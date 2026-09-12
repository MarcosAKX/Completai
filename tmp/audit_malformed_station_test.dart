// Diagnóstico local: demonstra o impacto de um posto malformado na lista inteira.
import 'package:completai/features/station_discovery/data/services/public_station_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('um prices inválido impede a consulta de retornar os postos válidos', () async {
    final firestore = FakeFirebaseFirestore();
    final stations = firestore.collection('public_stations');
    await stations.doc('valid').set({
      'brandName': 'Posto válido', 'citySearchKey': 'bebedouro', 'prices': {},
    });
    await stations.doc('invalid').set({
      'state': 'SP', 'city': 'Bebedouro', 'citySearchKey': 'bebedouro',
      'services': [], 'tags': [], 'prices': 'invalid',
    });
    await expectLater(PublicStationService(firestore).fetchByCityKey('bebedouro'),
        throwsA(isA<TypeError>()));
  });
}
