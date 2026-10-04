// Aba Avaliações do painel: leitura paginada e denúncia de reviews.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/station_details/data/services/station_details_service.dart';
import 'package:completai/features/station_details/domain/models/station_review.dart';
import 'package:completai/features/station_details/domain/models/station_review_page.dart';
import 'package:completai/features/station_panel/data/repositories/station_panel_reviews_repository_impl.dart';
import 'package:completai/features/station_panel/domain/repositories/station_panel_reviews_repository.dart';
import 'package:completai/features/station_panel/presentation/providers/station_panel_reviews_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _stationUid = 'station-1';
const _ownerUid = 'owner-1';

Future<FakeFirebaseFirestore> _seeded() async {
  final firestore = FakeFirebaseFirestore();
  await firestore
      .collection('public_stations')
      .doc(_stationUid)
      .collection('reviews')
      .doc('client-1')
      .set({
        'clientUid': 'client-1',
        'clientName': 'Ana',
        'rating': 5,
        'comment': 'Ótimo atendimento.',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 6)),
      });
  return firestore;
}

void main() {
  group('StationPanelReviewsRepositoryImpl', () {
    test('lê a página de avaliações do posto do dono', () async {
      final repository = StationPanelReviewsRepositoryImpl(
        StationDetailsService(await _seeded()),
        uidProvider: () => _ownerUid,
      );

      final page = await repository.loadReviews(_stationUid);

      expect(page.reviews, hasLength(1));
      expect(page.reviews.single.clientName, 'Ana');
    });

    test('reportReview grava com o uid do dono como denunciante', () async {
      final firestore = await _seeded();
      final repository = StationPanelReviewsRepositoryImpl(
        StationDetailsService(firestore),
        uidProvider: () => _ownerUid,
      );

      await repository.reportReview(
        stationUid: _stationUid,
        clientUid: 'client-1',
        reason: 'Comentário ofensivo.',
      );

      final report = await firestore
          .collection('public_stations')
          .doc(_stationUid)
          .collection('reviews')
          .doc('client-1')
          .collection('reports')
          .doc(_ownerUid)
          .get();
      expect(report.data()!['reporterUid'], _ownerUid);
    });

    test('sem sessão, reportReview lança falha de autenticação', () async {
      final repository = StationPanelReviewsRepositoryImpl(
        StationDetailsService(await _seeded()),
        uidProvider: () => null,
      );

      await expectLater(
        repository.reportReview(
          stationUid: _stationUid,
          clientUid: 'client-1',
          reason: 'motivo',
        ),
        throwsA(isA<UnauthenticatedException>()),
      );
    });
  });

  group('StationPanelReviewsViewModel', () {
    late FakeReviewsRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeReviewsRepository();
      container = ProviderContainer(
        overrides: [
          stationPanelReviewsRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('carrega a primeira página no build', () async {
      final state = await container.read(
        stationPanelReviewsViewModelProvider(_stationUid).future,
      );
      expect(state.reviews, hasLength(1));
      expect(state.reviews.single.clientName, 'Ana');
    });

    test('loadMore concatena a próxima página', () async {
      final provider = stationPanelReviewsViewModelProvider(_stationUid);
      await container.read(provider.future);
      repository.nextPageReviews = [_review('client-2', 'Bia')];
      repository.nextHasMore = false;

      final ok = await container.read(provider.notifier).loadMore();

      expect(ok, isTrue);
      final state = container.read(provider).requireValue;
      expect(state.reviews.map((r) => r.clientName), ['Ana', 'Bia']);
      expect(state.hasMore, isFalse);
    });

    test('reportReview devolve null no sucesso', () async {
      final provider = stationPanelReviewsViewModelProvider(_stationUid);
      final state = await container.read(provider.future);

      final error = await container
          .read(provider.notifier)
          .reportReview(state.reviews.single, 'motivo');

      expect(error, isNull);
      expect(repository.reportedReason, 'motivo');
    });

    test('reportReview devolve a mensagem da falha, sem quebrar a lista', () async {
      final provider = stationPanelReviewsViewModelProvider(_stationUid);
      final state = await container.read(provider.future);
      repository.reportFailure = const ValidationFailure('Descreva o motivo.');

      final error = await container
          .read(provider.notifier)
          .reportReview(state.reviews.single, '');

      expect(error, 'Descreva o motivo.');
      expect(container.read(provider).hasValue, isTrue);
    });

    test('reportReview também trata AppException cru do Repository', () async {
      final provider = stationPanelReviewsViewModelProvider(_stationUid);
      final state = await container.read(provider.future);
      repository.reportException = const UnauthenticatedException();

      final error = await container
          .read(provider.notifier)
          .reportReview(state.reviews.single, 'motivo');

      expect(error, 'Entre na conta para continuar.');
    });
  });
}

StationReview _review(String clientUid, String clientName) => StationReview(
  clientUid: clientUid,
  clientName: clientName,
  rating: 5,
  comment: 'Muito bom.',
  createdAt: DateTime(2026, 9, 6),
);

class FakeReviewsRepository implements StationPanelReviewsRepository {
  List<StationReview> firstPageReviews = [_review('client-1', 'Ana')];
  List<StationReview> nextPageReviews = const [];
  bool nextHasMore = false;
  Failure? reportFailure;
  AppException? reportException;
  String? reportedReason;

  @override
  Future<StationReviewPage> loadReviews(
    String stationUid, {
    StationReviewCursor? after,
    int limit = 20,
  }) async {
    if (after == null) {
      return StationReviewPage(
        reviews: firstPageReviews,
        nextCursor: const StationReviewCursor(
          seconds: 0,
          nanoseconds: 0,
          documentId: 'client-1',
        ),
        hasMore: true,
      );
    }
    return StationReviewPage(
      reviews: nextPageReviews,
      nextCursor: null,
      hasMore: nextHasMore,
    );
  }

  @override
  Future<void> reportReview({
    required String stationUid,
    required String clientUid,
    required String reason,
  }) async {
    final failure = reportFailure;
    if (failure != null) throw failure;
    final exception = reportException;
    if (exception != null) throw exception;
    reportedReason = reason;
  }
}
