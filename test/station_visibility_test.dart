// Posto só aparece para o motorista depois de aprovado — e posto cadastrado
// antes da fila existir (sem o campo `status`) continua aparecendo.
//
// Cobre os três caminhos pelos quais um motorista alcança um posto: a
// listagem da Home, o detalhe aberto direto e a lista de favoritos.
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/features/station_details/data/services/station_details_service.dart';
import 'package:completai/features/station_discovery/data/services/public_station_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _station({String? status}) => {
  'brandName': 'Posto Teste',
  'citySearchKey': 'bebedouro',
  'address': 'Rua Um, 100',
  'neighborhood': 'Centro',
  'city': 'Bebedouro',
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
  'status': ?status,
};

Future<FakeFirebaseFirestore> _seeded() async {
  final firestore = FakeFirebaseFirestore();
  await firestore
      .collection('public_stations')
      .doc('aprovado')
      .set(_station(status: 'approved'));
  await firestore
      .collection('public_stations')
      .doc('pendente')
      .set(_station(status: 'pending'));
  await firestore
      .collection('public_stations')
      .doc('recusado')
      .set(_station(status: 'rejected'));
  await firestore
      .collection('public_stations')
      .doc('legado')
      .set(_station()); // sem o campo
  return firestore;
}

void main() {
  test('Home lista só aprovado e legado', () async {
    final stations = await PublicStationService(
      await _seeded(),
    ).fetchByCityKey('bebedouro');

    expect(
      stations.map((s) => s.uid).toSet(),
      {'aprovado', 'legado'},
      reason: 'pendente e recusado não podem aparecer; legado não pode sumir',
    );
  });

  test('detalhe de posto pendente não abre', () async {
    final service = StationDetailsService(await _seeded());

    await expectLater(
      service.readStation('pendente'),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          // Mensagem igual à de posto inexistente de propósito: não cabe
          // contar ao cliente que existe um posto aguardando aprovação.
          'Posto não encontrado.',
        ),
      ),
    );
  });

  test('detalhe de posto recusado não abre', () async {
    final service = StationDetailsService(await _seeded());
    await expectLater(
      service.readStation('recusado'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('detalhe de aprovado e de legado abrem', () async {
    final service = StationDetailsService(await _seeded());

    expect((await service.readStation('aprovado')).uid, 'aprovado');
    expect((await service.readStation('legado')).uid, 'legado');
  });

  test('favoritos omitem posto não aprovado', () async {
    final service = StationDetailsService(await _seeded());

    final found = await service.readExistingStations([
      'aprovado',
      'pendente',
      'recusado',
      'legado',
    ]);

    expect(found.map((s) => s.uid).toSet(), {'aprovado', 'legado'});
  });
}
