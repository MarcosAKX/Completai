// O MVP oferece apenas Bebedouro sem consultar todos os postos no Firestore.
import 'package:completai/features/station_discovery/domain/station_discovery_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cidade disponível no MVP é somente Bebedouro', () {
    expect(StationDiscoveryScope.availableCities, const ['Bebedouro']);
  });
}
