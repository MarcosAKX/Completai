// Cliente denuncia a avaliação de OUTRO cliente, pelo perfil público.
//
// Mesma coleção e mesmo caminho que o painel do posto usa — o id do
// documento é o uid de quem denuncia, então cliente e posto convivem sem
// sobrescrever um ao outro.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/station_details/data/repositories/station_details_repository_impl.dart';
import 'package:completai/features/station_details/data/services/station_details_service.dart';
import 'package:completai/features/station_details/data/services/station_directions_service.dart';
import 'package:completai/features/station_details/domain/models/station_details_state.dart';
import 'package:completai/features/station_details/domain/models/station_review.dart';
import 'package:completai/features/station_details/domain/repositories/station_details_repository.dart';
import 'package:completai/features/station_details/presentation/providers/station_details_providers.dart';
import 'package:completai/shared/models/report_reason.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _stationUid = 'posto-1';
const _autor = 'bob';
const _denunciante = 'alice';

Future<FakeFirebaseFirestore> _seeded() async {
  final firestore = FakeFirebaseFirestore();
  await firestore.collection('public_stations').doc(_stationUid).set({
    'brandName': 'Posto Teste',
    'address': 'Rua Um, 100',
    'neighborhood': 'Centro',
    'city': 'Bebedouro',
    'citySearchKey': 'bebedouro',
    'state': 'SP',
    'latitude': -20.9,
    'longitude': -48.4,
    'prices': const {
      'gasolineRegular': 6.29,
      'gasolineAdditive': null,
      'ethanol': null,
      'dieselS10': null,
      'dieselS500': null,
    },
    'openingHours': const {'monday': null},
    'averageRating': 4.0,
    'reviewCount': 1,
    'services': const <String>[],
    'tags': const <String>[],
    'status': 'approved',
  });
  await firestore
      .collection('public_stations')
      .doc(_stationUid)
      .collection('reviews')
      .doc(_autor)
      .set({
        'clientUid': _autor,
        'clientName': 'Bob',
        'rating': 1,
        'comment': 'Comentário ofensivo',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
      });
  return firestore;
}

StationDetailsRepositoryImpl _repository(
  FakeFirebaseFirestore firestore, {
  required String? Function() uid,
}) => StationDetailsRepositoryImpl(
  StationDetailsService(firestore),
  const StationDirectionsService(),
  uidProvider: uid,
);

const _review = StationReview(
  clientUid: _autor,
  clientName: 'Bob',
  rating: 1,
  comment: 'Comentário ofensivo',
  createdAt: null,
);

void main() {
  group('Repository', () {
    test('grava a denúncia sob a avaliação, com o uid de quem denunciou', () async {
      final firestore = await _seeded();

      await _repository(
        firestore,
        uid: () => _denunciante,
      ).reportReview(
        stationUid: _stationUid,
        clientUid: _autor,
        reason: ReportReason.offensive,
      );

      final doc = await firestore
          .collection('public_stations')
          .doc(_stationUid)
          .collection('reviews')
          .doc(_autor)
          .collection('reports')
          .doc(_denunciante)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['reporterUid'], _denunciante);
      expect(doc.data()!['reason'], 'offensive');
      // Quem denuncia nunca define o veredito.
      expect(doc.data()!['status'], 'pending');
    });

    test('denunciar não apaga nem altera a avaliação', () async {
      final firestore = await _seeded();

      await _repository(firestore, uid: () => _denunciante).reportReview(
        stationUid: _stationUid,
        clientUid: _autor,
        reason: ReportReason.fake,
      );

      // A avaliação some só se o admin aprovar a denúncia.
      final review = await firestore
          .collection('public_stations')
          .doc(_stationUid)
          .collection('reviews')
          .doc(_autor)
          .get();
      expect(review.exists, isTrue);

      final posto =
          (await firestore.collection('public_stations').doc(_stationUid).get())
              .data()!;
      expect(posto['reviewCount'], 1);
      expect(posto['averageRating'], 4.0);
    });

    test('denunciar a própria avaliação é recusado', () async {
      final firestore = await _seeded();

      // `reportReview` não é `async`: a checagem roda antes do `guardInfra`
      // e a exceção sai de forma síncrona, na hora da chamada. Passar o
      // Future pronto faria ela escapar antes do matcher.
      await expectLater(
        () => _repository(firestore, uid: () => _autor).reportReview(
          stationUid: _stationUid,
          clientUid: _autor,
          reason: ReportReason.spam,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('própria avaliação'),
          ),
        ),
      );
    });

    test('sem sessão, denunciar lança falha de autenticação', () async {
      final firestore = await _seeded();

      await expectLater(
        () => _repository(firestore, uid: () => null).reportReview(
          stationUid: _stationUid,
          clientUid: _autor,
          reason: ReportReason.spam,
        ),
        throwsA(isA<UnauthenticatedException>()),
      );
    });

    test('cliente e posto denunciam sem sobrescrever um ao outro', () async {
      final firestore = await _seeded();

      await _repository(firestore, uid: () => _denunciante).reportReview(
        stationUid: _stationUid,
        clientUid: _autor,
        reason: ReportReason.offensive,
      );
      await _repository(firestore, uid: () => _stationUid).reportReview(
        stationUid: _stationUid,
        clientUid: _autor,
        reason: ReportReason.fake,
      );

      final reports = await firestore
          .collection('public_stations')
          .doc(_stationUid)
          .collection('reviews')
          .doc(_autor)
          .collection('reports')
          .get();

      expect(reports.docs, hasLength(2));
      expect(
        reports.docs.map((d) => d.id).toSet(),
        {_denunciante, _stationUid},
      );
    });
  });

  group('ViewModel', () {
    ProviderContainer container(StationDetailsRepository repository) {
      final c = ProviderContainer(
        overrides: [
          stationDetailsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('devolve null no sucesso e mantém a avaliação na lista', () async {
      final firestore = await _seeded();
      final c = container(
        _repository(firestore, uid: () => _denunciante),
      );
      final provider = stationDetailsViewModelProvider(_stationUid);
      final antes = await c.read(provider.future);

      final erro = await c
          .read(provider.notifier)
          .reportReview(_review, ReportReason.offensive);

      expect(erro, isNull);
      // Nada muda na tela: a denúncia foi enviada, não executada.
      expect(c.read(provider).requireValue.reviews, antes.reviews);
    });

    test('devolve a mensagem quando é a própria avaliação', () async {
      final firestore = await _seeded();
      final c = container(_repository(firestore, uid: () => _autor));
      final provider = stationDetailsViewModelProvider(_stationUid);
      await c.read(provider.future);

      final erro = await c
          .read(provider.notifier)
          .reportReview(_review, ReportReason.offensive);

      expect(erro, contains('própria avaliação'));
      // Erro de denúncia não pode derrubar a tela do posto.
      expect(c.read(provider).hasValue, isTrue);
    });

    test('devolve a mensagem quando não há sessão', () async {
      final firestore = await _seeded();
      final c = container(_repository(firestore, uid: () => null));
      final provider = stationDetailsViewModelProvider(_stationUid);
      await c.read(provider.future);

      final erro = await c
          .read(provider.notifier)
          .reportReview(_review, ReportReason.offensive);

      expect(erro, isNotNull);
      expect(c.read(provider).hasValue, isTrue);
    });

    test('falha de infra vira mensagem, não exceção solta', () async {
      final firestore = await _seeded();
      final c = container(
        _FalhaRepository(_repository(firestore, uid: () => _denunciante)),
      );
      final provider = stationDetailsViewModelProvider(_stationUid);
      await c.read(provider.future);

      final erro = await c
          .read(provider.notifier)
          .reportReview(_review, ReportReason.spam);

      expect(erro, 'Sem conexão.');
    });
  });
}

/// Carrega pelo repositório real e falha só ao denunciar — assim o teste
/// exercita o catch de `Failure` sem precisar montar um estado à mão.
class _FalhaRepository implements StationDetailsRepository {
  _FalhaRepository(this._inner);

  final StationDetailsRepository _inner;

  @override
  Future<StationDetailsState> load(
    String stationUid, {
    bool forceRefresh = false,
  }) => _inner.load(stationUid, forceRefresh: forceRefresh);

  @override
  Future<void> reportReview({
    required String stationUid,
    required String clientUid,
    required ReportReason reason,
  }) async => throw const NetworkFailure('Sem conexão.');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
