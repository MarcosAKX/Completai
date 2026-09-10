// Converte apenas coordenadas atuais do aparelho; não serve para endereços de postos.
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';

class ResolvedCity {
  const ResolvedCity(this.city);
  final String city;
}

class CityGeocodingService {
  CityGeocodingService({
    required this.client,
    bool? useNative,
    this.nativeLookup,
    this.timeout = const Duration(seconds: 10),
  }) : _useNative = useNative ?? !kIsWeb;

  final http.Client client;
  final bool _useNative;
  final Future<List<Placemark>> Function(double, double)? nativeLookup;
  final Duration timeout;

  Future<ResolvedCity> resolve(double latitude, double longitude) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw const LocationUnavailableException();
    }
    if (_useNative) {
      List<Placemark> marks = [];
      try {
        final lookup = nativeLookup ?? Geocoding().placemarkFromCoordinates;
        marks = await lookup(latitude, longitude).timeout(timeout);
      } catch (error) {
        // Não registra posição ou URL da consulta no log.
        developer.log(
          'Geocoder nativo indisponível (${error.runtimeType}); usando HTTP.',
          name: 'location',
        );
      }
      if (marks.isNotEmpty) {
        final mark = marks.first;
        final area = (mark.administrativeArea ?? '').trim();
        final city = _firstText([mark.locality, mark.subAdministrativeArea]);
        if (area.isNotEmpty) _validateState(area, mark.isoCountryCode);
        if (area.isNotEmpty && city.isNotEmpty) return ResolvedCity(city);
      }
    }
    return _httpCity(latitude, longitude);
  }

  Future<ResolvedCity> _httpCity(double latitude, double longitude) async {
    final uri = Uri.https(
      'api.bigdatacloud.net',
      '/data/reverse-geocode-client',
      {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'localityLanguage': 'pt',
      },
    );
    try {
      final response = await client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        throw const LocationUnavailableException();
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const LocationUnavailableException();
      }
      final country = body['countryCode'];
      final state = body['principalSubdivisionCode'];
      if (country is! String ||
          state is! String ||
          country.isEmpty ||
          state.isEmpty) {
        throw const LocationUnavailableException();
      }
      _validateState(state, country);
      // locality pode ser bairro; não o usa como município para buscar postos.
      final city = body['city'];
      if (city is! String || city.trim().isEmpty) {
        throw const LocationUnavailableException();
      }
      return ResolvedCity(city.trim());
    } on AppException {
      rethrow;
    } catch (error) {
      developer.log(
        'Conversão de localização falhou (${error.runtimeType}).',
        name: 'location',
      );
      throw const LocationUnavailableException();
    }
  }

  void _validateState(String area, String? country) {
    final state = area.trim().toUpperCase();
    if ((country != null &&
            country.trim().isNotEmpty &&
            country.toUpperCase() != 'BR') ||
        !['SP', 'BR-SP', 'SÃO PAULO', 'SAO PAULO'].contains(state)) {
      throw const ValidationException(
        'No momento, o CompletAI atende apenas o estado de São Paulo.',
      );
    }
  }

  String _firstText(List<String?> values) => values
      .whereType<String>()
      .map((value) => value.trim())
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
}
