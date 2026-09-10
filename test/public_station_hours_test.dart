// Regressão: consulta da Home deve preservar o expediente iniciado ontem.
import 'package:completai/features/station_discovery/data/services/public_station_service.dart';
import 'package:completai/features/station_discovery/domain/station_opening_hours.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home considera expediente anterior mesmo com hoje fechado', () async {
    final firestore = FakeFirebaseFirestore();
    final today = DateTime.now();
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    await firestore.collection('public_stations').doc('station').set({
      'citySearchKey': 'bebedouro',
      'openingHours': {
        days[(today.weekday + 5) % 7]: {'open': '18:00', 'close': '02:00'},
        days[today.weekday - 1]: null,
      },
    });
    final stations = await PublicStationService(
      firestore,
    ).fetchByCityKey('bebedouro');
    final oneAm = DateTime(today.year, today.month, today.day, 1);
    expect(isStationOpen(oneAm, stations.single.openingHours), isTrue);
  });
}
