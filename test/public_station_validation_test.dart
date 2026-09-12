// Um documento inválido não pode impedir a leitura dos demais postos.
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/features/station_discovery/data/services/public_station_service.dart';
import 'package:completai/features/station_details/data/services/station_details_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final invalid in <String, Object>{
    'prices': 'invalid',
    'openingHours': [],
    'brandName': 123,
    'pricesUpdatedAt': 'ontem',
    'latitude': 91,
    'averageRating': 6,
    'reviewCount': 1.5,
    'services': 'loja',
  }.entries) {
    test(
      'isola ${invalid.key} inválido na Home e nas listas; detalhe falha tipado',
      () async {
        final firestore = FakeFirebaseFirestore();
        final valid = <String, Object?>{
          'citySearchKey': 'bebedouro',
          'brandName': 'Posto válido',
          'prices': {'gasolineRegular': 5.79, 'ethanol': null},
        };
        await firestore.collection('public_stations').doc('valid').set(valid);
        await firestore.collection('public_stations').doc('bad').set({
          ...valid,
          invalid.key: invalid.value,
        });
        expect(
          (await PublicStationService(
            firestore,
          ).fetchByCityKey('bebedouro')).map((s) => s.uid),
          ['valid'],
        );
        final details = StationDetailsService(firestore);
        expect(
          (await details.readExistingStations([
            'bad',
            'valid',
          ])).map((s) => s.uid),
          ['valid'],
        );
        await expectLater(
          details.readStation('bad'),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  }
  test('preços inválidos dentro do mapa também são isolados', () async {
    final firestore = FakeFirebaseFirestore();
    for (final value in ['5,79', -1, 0, 100, double.nan, double.infinity]) {
      await firestore.collection('public_stations').doc('bad').set({
        'citySearchKey': 'bebedouro',
        'prices': {'ethanol': value},
      });
      expect(
        await PublicStationService(firestore).fetchByCityKey('bebedouro'),
        isEmpty,
      );
    }
  });
}
