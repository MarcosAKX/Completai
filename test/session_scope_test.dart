// Regressão: trocar de conta não pode mostrar o dado da conta anterior.
//
// Os providers de Repository não são `autoDispose` e guardam cache em
// memória, então sobrevivem ao logout. Dois mecanismos protegem disso: o
// `AuthGate` descarta os providers quando o uid muda, e os repositories
// guardam o uid junto do cache. Este arquivo cobre o segundo — é o que vale
// mesmo que o primeiro falhe.
import 'package:completai/features/station_details/data/repositories/station_details_repository_impl.dart';
import 'package:completai/features/station_details/data/services/station_details_service.dart';
import 'package:completai/features/station_details/data/services/station_directions_service.dart';
import 'package:completai/features/station_panel/data/repositories/station_panel_repository_impl.dart';
import 'package:completai/features/station_panel/data/services/station_panel_service.dart';
import 'package:completai/shared/services/address_geocoding_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubGeocoding extends AddressGeocodingService {
  @override
  Future<StationCoordinates> resolve(StationAddressInput input) async =>
      const StationCoordinates(-20.9, -48.4, 'SP', 'Bebedouro', 'bebedouro');
}

Map<String, dynamic> _public(String nome) => {
  'brandName': nome,
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
  'averageRating': 0.0,
  'reviewCount': 0,
  'services': const <String>[],
  'tags': const <String>[],
  'status': 'approved',
};

Map<String, dynamic> _private(String uid, String nome) => {
  'uid': uid,
  'type': 'gas_station',
  'cnpj': '12345678000190',
  'email': 'contato@example.test',
  'phone': '(17) 3333-4444',
  'brandName': nome,
};

void main() {
  test('painel não devolve o perfil do posto anterior após troca de conta', () async {
    final firestore = FakeFirebaseFirestore();
    for (final (uid, nome) in [('posto-a', 'Posto A'), ('posto-b', 'Posto B')]) {
      await firestore.collection('public_stations').doc(uid).set(_public(nome));
      await firestore.collection('gas_stations').doc(uid).set(_private(uid, nome));
    }

    // Um uid mutável simula o Firebase Auth trocando de conta sem o app
    // reiniciar — que é exatamente o cenário do bug.
    String? uid = 'posto-a';
    final repository = StationPanelRepositoryImpl(
      StationPanelService(firestore, _StubGeocoding()),
      uidProvider: () => uid,
    );

    expect((await repository.loadProfile()).name, 'Posto A');
    // Segunda leitura vem do cache — é o caminho que estava quebrado.
    expect((await repository.loadProfile()).name, 'Posto A');

    uid = 'posto-b';

    expect(
      (await repository.loadProfile()).name,
      'Posto B',
      reason: 'o cache é do posto A e não pode valer para o posto B',
    );
  });

  test('detalhe não devolve favorito nem "já avaliei" da conta anterior', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('public_stations').doc('p1').set(_public('Posto Um'));
    // Cliente A favoritou e avaliou; cliente B não fez nada.
    await firestore
        .collection('users')
        .doc('cliente-a')
        .collection('favorites')
        .doc('p1')
        .set({'stationId': 'p1'});
    await firestore
        .collection('public_stations')
        .doc('p1')
        .collection('reviews')
        .doc('cliente-a')
        .set({
          'clientUid': 'cliente-a',
          'clientName': 'A',
          'rating': 5,
          'comment': '',
        });

    String? uid = 'cliente-a';
    final repository = StationDetailsRepositoryImpl(
      StationDetailsService(firestore),
      const StationDirectionsService(),
      uidProvider: () => uid,
    );

    final deA = await repository.load('p1');
    expect(deA.isFavorite, isTrue);
    expect(deA.hasReviewed, isTrue);

    uid = 'cliente-b';

    final deB = await repository.load('p1');
    expect(deB.isFavorite, isFalse, reason: 'favorito é do cliente A');
    expect(deB.hasReviewed, isFalse, reason: 'quem avaliou foi o cliente A');
  });
}
