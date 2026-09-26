// "Como chegar": o destino é o endereço em texto, não a coordenada gravada.
//
// O OSM quase não tem número de porta no interior de SP, então a coordenada
// que gravamos é o centro da via. O Google Maps resolve o texto direito.
import 'package:completai/features/station_details/data/services/station_directions_service.dart';
import 'package:flutter_test/flutter_test.dart';

String _query({
  String address = 'Avenida Brasil, 1000',
  String neighborhood = 'Centro',
  String city = 'Bebedouro',
  String state = 'SP',
  double latitude = -20.949,
  double longitude = -48.479,
}) => StationDirectionsService.buildQuery(
  address: address,
  neighborhood: neighborhood,
  city: city,
  state: state,
  latitude: latitude,
  longitude: longitude,
);

void main() {
  test('usa o endereço completo, do número ao país', () {
    expect(_query(), 'Avenida Brasil, 1000, Centro, Bebedouro, SP, Brasil');
  });

  test('não manda a coordenada quando há endereço', () {
    expect(_query(), isNot(contains('-20.949')));
  });

  test('pula partes vazias sem deixar vírgula solta', () {
    expect(
      _query(neighborhood: '', state: '   '),
      'Avenida Brasil, 1000, Bebedouro, Brasil',
    );
  });

  test('documento sem endereço cai na coordenada', () {
    expect(
      _query(address: '', neighborhood: '', city: '', state: ''),
      '-20.949,-48.479',
    );
  });
}
