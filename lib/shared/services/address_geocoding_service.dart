// Resolve um endereço livre em coordenadas + cidade canônica, validando a UF.
//
// Compartilhado: usado no cadastro do posto (`auth`) e na edição de endereço
// pelo dono (`station_panel`). Roda 1x por operação, nunca em listagem.
//
// Estratégia: tenta o plugin nativo `geocoding` (Android/iOS); se ele não
// existe (web/desktop) ou falha (Geocoder do emulador cai), cai no fallback
// HTTP do Nominatim (OpenStreetMap, grátis, sem chave). A validação de SP e a
// extração de cidade são as mesmas nos dois caminhos.
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

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

class _RawGeocode {
  const _RawGeocode(this.latitude, this.longitude, this.state, this.city);
  final double latitude;
  final double longitude;
  final String state;
  final String city;
}

class AddressGeocodingService {
  AddressGeocodingService({http.Client? httpClient})
    : _http = httpClient ?? http.Client(),
      _nativeLocations = null,
      _nativePlacemarks = null;

  /// Injeta o caminho nativo para teste. O HTTP continua substituível.
  AddressGeocodingService.forTesting(
    this._nativeLocations,
    this._nativePlacemarks, {
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Future<List<Location>> Function(String)? _nativeLocations;
  final Future<List<Placemark>> Function(String)? _nativePlacemarks;

  Future<StationCoordinates> resolve(String address) async {
    final native = await _tryNative(address);
    if (native != null) return _validate(native);

    final (fromHttp, httpFailed) = await _tryHttp(address);
    if (fromHttp != null) return _validate(fromHttp);

    throw ValidationException(
      httpFailed
          ? 'Não foi possível confirmar o endereço agora. Verifique sua '
                'conexão e tente de novo.'
          : 'Endereço não encontrado. Confira o endereço do posto.',
    );
  }

  Future<_RawGeocode?> _tryNative(String address) async {
    final geocoding = (_nativeLocations == null || _nativePlacemarks == null)
        ? Geocoding()
        : null;
    final findLocations = _nativeLocations ?? geocoding!.locationFromAddress;
    final findPlacemarks = _nativePlacemarks ?? geocoding!.placemarkFromAddress;
    try {
      final results = await Future.wait([
        findLocations(address),
        findPlacemarks(address),
      ]);
      final locations = results[0] as List<Location>;
      final placemarks = results[1] as List<Placemark>;
      if (locations.isEmpty || placemarks.isEmpty) return null;
      final place = placemarks.first;
      final location = locations.first;
      final state = (place.administrativeArea ?? '').trim();
      final city = (place.locality ?? place.subAdministrativeArea ?? '').trim();
      if (state.isEmpty || city.isEmpty) return null;
      return _RawGeocode(location.latitude, location.longitude, state, city);
    } on Exception {
      // Plugin indisponível (web/desktop) ou Geocoder do Android falhou.
      // Não engolimos o erro — só trocamos de estratégia para o HTTP.
      return null;
    }
  }

  /// Retorna `(resultado, falhouPorErro)`. `falhouPorErro` é `true` quando a
  /// requisição em si quebrou (rede, CORS, timeout) — para diferenciar de
  /// "endereço realmente não existe".
  Future<(_RawGeocode?, bool)> _tryHttp(String address) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': address,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '1',
      'countrycodes': 'br',
      'accept-language': 'pt-BR',
    });
    try {
      final response = await _http
          .get(uri, headers: const {'User-Agent': 'CompletAI/1.0 (TCC)'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return (null, true);
      final body = jsonDecode(response.body);
      if (body is! List) return (null, true);
      if (body.isEmpty) return (null, false);
      final first = body.first;
      if (first is! Map) return (null, true);
      final address0 = first['address'];
      final lat = double.tryParse('${first['lat']}');
      final lon = double.tryParse('${first['lon']}');
      if (lat == null || lon == null || address0 is! Map) return (null, true);
      final state = '${address0['state'] ?? ''}'.trim();
      final city =
          '${address0['city'] ?? address0['town'] ?? address0['municipality'] ?? address0['village'] ?? ''}'
              .trim();
      if (state.isEmpty || city.isEmpty) return (null, true);
      return (_RawGeocode(lat, lon, state, city), false);
    } on Exception {
      // Rede/CORS/timeout — não é "endereço inexistente".
      return (null, true);
    }
  }

  StationCoordinates _validate(_RawGeocode raw) {
    final area = raw.state.toUpperCase();
    final isSaoPaulo =
        area == FirestoreCollections.defaultState ||
        area == 'SÃO PAULO' ||
        area == 'SAO PAULO';
    if (!isSaoPaulo) {
      throw const ValidationException(
        'Cadastro disponível apenas para postos no estado de São Paulo.',
      );
    }
    if (!raw.latitude.isFinite ||
        !raw.longitude.isFinite ||
        raw.latitude.abs() > 90 ||
        raw.longitude.abs() > 180) {
      throw const ValidationException(
        'O endereço retornou coordenadas inválidas.',
      );
    }
    return StationCoordinates(
      raw.latitude,
      raw.longitude,
      FirestoreCollections.defaultState,
      raw.city,
      citySearchKey(raw.city),
    );
  }
}
