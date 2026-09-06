// Resolve um endereço livre em coordenadas + cidade canônica, validando a UF.
//
// Compartilhado: usado no cadastro do posto (`auth`) e na edição de endereço
// pelo dono (`station_panel`). A geocodificação roda 1x por operação, nunca
// em tempo de listagem.
import 'package:geocoding/geocoding.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/city_search_key.dart';

class StationCoordinates {
  const StationCoordinates(
    this.latitude,
    this.longitude,
    this.state,
    this.city,
    this.citySearchKey,
  );
  final double latitude;
  final double longitude;
  final String state;
  final String city;
  final String citySearchKey;
}

class AddressGeocodingService {
  AddressGeocodingService() : _findLocations = null, _findPlacemarks = null;
  AddressGeocodingService.forTesting(this._findLocations, this._findPlacemarks);
  final Future<List<Location>> Function(String)? _findLocations;
  final Future<List<Placemark>> Function(String)? _findPlacemarks;

  Future<StationCoordinates> resolve(String address) async {
    final geocoding = _findLocations == null || _findPlacemarks == null
        ? Geocoding()
        : null;
    final findLocations = _findLocations ?? geocoding!.locationFromAddress;
    final findPlacemarks = _findPlacemarks ?? geocoding!.placemarkFromAddress;
    final results = await Future.wait([
      findLocations(address),
      findPlacemarks(address),
    ]);
    final locations = results[0] as List<Location>;
    final placemarks = results[1] as List<Placemark>;
    if (locations.isEmpty || placemarks.isEmpty) {
      throw const ValidationException(
        'Endereço não encontrado. Confira o endereço do posto.',
      );
    }
    final area = placemarks.first.administrativeArea?.trim().toUpperCase();
    final isSaoPaulo =
        area == FirestoreCollections.defaultState ||
        area == 'SÃO PAULO' ||
        area == 'SAO PAULO';
    if (!isSaoPaulo) {
      throw const ValidationException(
        'Cadastro disponível apenas para postos no estado de São Paulo.',
      );
    }
    final placemark = placemarks.first;
    final city = (placemark.locality ?? placemark.subAdministrativeArea ?? '')
        .trim();
    if (city.isEmpty) {
      throw const ValidationException(
        'Não foi possível confirmar a cidade do endereço.',
      );
    }
    final location = locations.first;
    if (!location.latitude.isFinite ||
        !location.longitude.isFinite ||
        location.latitude.abs() > 90 ||
        location.longitude.abs() > 180) {
      throw const ValidationException(
        'O endereço retornou coordenadas inválidas.',
      );
    }
    return StationCoordinates(
      location.latitude,
      location.longitude,
      FirestoreCollections.defaultState,
      city,
      citySearchKey(city),
    );
  }
}
