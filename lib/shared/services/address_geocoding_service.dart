// Resolve um endereço estruturado em coordenadas + cidade canônica, validando a UF.
//
// Compartilhado: usado no cadastro do posto (`auth`) e na edição de endereço
// pelo dono (`station_panel`). Roda 1x por operação, nunca em listagem.
//
// Estratégia: tenta o plugin nativo `geocoding` (Android/iOS); se ele não
// existe (web/desktop) ou falha (Geocoder do emulador cai), cai no fallback
// HTTP do Nominatim (OpenStreetMap, grátis, sem chave). No HTTP tenta primeiro
// a busca estruturada (rua/número/CEP/cidade em campos separados, mais
// precisa) e depois a busca livre, que é o comportamento antigo e continua
// funcionando quando o CEP está errado ou o OSM não conhece aquele logradouro.
// A validação de SP e a extração de cidade são as mesmas em todos os caminhos.
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/firestore_collections.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/city_search_key.dart';

/// Endereço como o dono digita: em partes, não numa linha só.
class StationAddressInput {
  const StationAddressInput({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    this.cep = '',
  });

  /// Rua/avenida, sem o número.
  final String street;

  /// Número do imóvel — aceita "S/N".
  final String number;

  final String neighborhood;
  final String city;

  /// CEP como digitado (com ou sem máscara). Opcional.
  final String cep;

  String get cepDigits => cep.replaceAll(RegExp(r'\D'), '');

  bool get hasCep => cepDigits.length == 8;

  /// Linha exibida ao cliente e gravada em `public_stations.address`.
  String get line {
    final trimmedStreet = street.trim();
    final trimmedNumber = number.trim();
    if (trimmedNumber.isEmpty) return trimmedStreet;
    return '$trimmedStreet, $trimmedNumber';
  }

  /// Inverso de [line], para postos gravados antes de `street`/`number`
  /// existirem: o cadastro antigo tinha um campo único e a convenção do hint
  /// era "Avenida Brasil, 1000". Sem vírgula, tudo vira logradouro.
  static (String street, String number) splitLegacyLine(String address) {
    final text = address.trim();
    final comma = text.lastIndexOf(',');
    if (comma <= 0 || comma == text.length - 1) return (text, '');
    final tail = text.substring(comma + 1).trim();
    final looksLikeNumber =
        tail.isNotEmpty &&
        tail.length <= 10 &&
        RegExp(r'^(s/?n|\d+[a-zA-Z]?)$', caseSensitive: false).hasMatch(tail);
    if (!looksLikeNumber) return (text, '');
    return (text.substring(0, comma).trim(), tail);
  }

  /// Consulta livre — usada pelo geocoder nativo e como último recurso no HTTP.
  String get freeForm => [
    line,
    neighborhood.trim(),
    city.trim(),
    if (hasCep) '${cepDigits.substring(0, 5)}-${cepDigits.substring(5)}',
    'Brasil',
  ].where((part) => part.isNotEmpty).join(', ');
}

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

  Future<StationCoordinates> resolve(StationAddressInput input) async {
    final native = await _tryNative(input.freeForm);
    if (native != null) return _validate(native);

    // Estruturada primeiro (mais precisa), livre depois (mais tolerante).
    var requestFailed = false;
    for (final uri in _httpQueries(input)) {
      final (result, failed) = await _tryHttp(uri);
      if (result != null) return _validate(result);
      requestFailed = requestFailed || failed;
    }

    throw ValidationException(
      requestFailed
          ? 'Não foi possível confirmar o endereço agora. Verifique sua '
                'conexão e tente de novo.'
          : 'Endereço não encontrado. Confira rua, número, bairro e CEP.',
    );
  }

  Future<_RawGeocode?> _tryNative(String address) async {
    try {
      final geocoding = _nativeLocations == null ? Geocoding() : null;
      final findLocations = _nativeLocations ?? geocoding!.locationFromAddress;
      final findPlacemarks =
          _nativePlacemarks ?? geocoding!.placemarkFromAddress;
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
    } catch (error, stack) {
      // Plataforma sem implementação nativa (na web o `Geocoding()` lança
      // `TypeError` porque `GeocodingPlatformFactory.instance` é null — e
      // isso é `Error`, não `Exception`), ou o Geocoder do Android falhou.
      // Não engolimos: registramos e trocamos para o fallback HTTP.
      developer.log(
        'geocoding nativo indisponível — usando fallback HTTP',
        name: 'geocoding',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Nominatim não aceita busca estruturada e livre na mesma requisição, então
  /// são duas URLs distintas, tentadas em ordem.
  List<Uri> _httpQueries(StationAddressInput input) {
    const common = {
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '1',
      'countrycodes': 'br',
      'accept-language': 'pt-BR',
    };

    final number = input.number.trim();
    final street = input.street.trim();
    final structured = <String, String>{
      ...common,
      // Convenção do Nominatim: número antes do logradouro.
      'street': number.isEmpty ? street : '$number $street',
      'city': input.city.trim(),
      'state': 'São Paulo',
      'country': 'Brasil',
      if (input.hasCep) 'postalcode': input.cepDigits,
    };

    return [
      Uri.https('nominatim.openstreetmap.org', '/search', structured),
      Uri.https('nominatim.openstreetmap.org', '/search', {
        ...common,
        'q': input.freeForm,
      }),
    ];
  }

  /// Retorna `(resultado, falhouPorErro)`. `falhouPorErro` é `true` quando a
  /// requisição em si quebrou (rede, CORS, timeout) — para diferenciar de
  /// "endereço realmente não existe".
  Future<(_RawGeocode?, bool)> _tryHttp(Uri uri) async {
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
    } catch (error, stack) {
      // Rede/CORS/timeout/resposta inesperada — não é "endereço inexistente".
      developer.log(
        'fallback HTTP de geocoding falhou',
        name: 'geocoding',
        error: error,
        stackTrace: stack,
      );
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
