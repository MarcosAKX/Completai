import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:completai/features/station_discovery/data/services/public_station_service.dart';

void main() {
  group('PublicStationService', () {
    test(
      'fetchAvailableCities retorna cidades únicas e em ordem alfabética',
      () async {
        final firestore = FakeFirebaseFirestore();

        await firestore.collection('public_stations').add({
          'city': 'Bebedouro',
          'citySearchKey': 'bebedouro',
        });

        await firestore.collection('public_stations').add({
          'city': 'Bebedouro',
          'citySearchKey': 'bebedouro',
        });

        await firestore.collection('public_stations').add({
          'city': 'Barretos',
          'citySearchKey': 'barretos',
        });

        final service = PublicStationService(firestore);

        final cities = await service.fetchAvailableCities();

        expect(
          cities,
          [
            'Barretos',
            'Bebedouro',
          ],
        );
      },
    );

    test(
      'fetchAvailableCities ignora cidades vazias ou ausentes',
      () async {
        final firestore = FakeFirebaseFirestore();

        await firestore.collection('public_stations').add({
          'city': 'Bebedouro',
        });

        await firestore.collection('public_stations').add({
          'city': '',
        });

        await firestore.collection('public_stations').add({
          'brandName': 'Posto sem cidade',
        });

        final service = PublicStationService(firestore);

        final cities = await service.fetchAvailableCities();

        expect(
          cities,
          ['Bebedouro'],
        );
      },
    );
  });
}