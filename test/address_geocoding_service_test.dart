// Geocodificação: caminho nativo, validação de SP e fallback HTTP (Nominatim).
import 'dart:convert';

import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/shared/services/address_geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<List<Location>> _location(String _) async => [
  Location(latitude: -23.55, longitude: -46.63, timestamp: DateTime(2026)),
];

/// Client HTTP que falha o teste se for chamado (o caminho nativo bastou).
http.Client get _forbiddenHttp => MockClient((_) async {
  fail('não deveria chamar o Nominatim quando o nativo respondeu');
});

http.Client _nominatim(List<Map<String, dynamic>> results) =>
    MockClient((_) async => http.Response(jsonEncode(results), 200));

void main() {
  group('caminho nativo', () {
    test('aceita São Paulo e normaliza state para SP', () async {
      final service = AddressGeocodingService.forTesting(
        _location,
        (_) async => [
          Placemark(administrativeArea: 'São Paulo', locality: 'Campinas'),
        ],
        httpClient: _forbiddenHttp,
      );
      final result = await service.resolve('Rua X, Campinas, Brasil');
      expect(result.state, 'SP');
      expect(result.city, 'Campinas');
      expect(result.citySearchKey, 'campinas');
      expect(result.latitude, -23.55);
    });

    test('rejeita endereço fora de SP', () async {
      final service = AddressGeocodingService.forTesting(
        _location,
        (_) async => [
          Placemark(administrativeArea: 'RJ', locality: 'Rio de Janeiro'),
        ],
        httpClient: _forbiddenHttp,
      );
      await expectLater(
        service.resolve('Copacabana, RJ'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Cadastro disponível apenas para postos no estado de São Paulo.',
          ),
        ),
      );
    });
  });

  group('fallback HTTP (nativo indisponível)', () {
    test('usa o Nominatim quando o plugin nativo lança', () async {
      final service = AddressGeocodingService.forTesting(
        (_) async => throw Exception('MissingPluginException'),
        (_) async => throw Exception('MissingPluginException'),
        httpClient: _nominatim([
          {
            'lat': '-21.03',
            'lon': '-48.47',
            'address': {'state': 'São Paulo', 'city': 'Bebedouro'},
          },
        ]),
      );
      final result = await service.resolve('Rua 7, Bebedouro');
      expect(result.state, 'SP');
      expect(result.city, 'Bebedouro');
      expect(result.citySearchKey, 'bebedouro');
      expect(result.latitude, closeTo(-21.03, 1e-6));
    });

    test('Nominatim fora de SP é rejeitado', () async {
      final service = AddressGeocodingService.forTesting(
        (_) async => throw Exception('sem plugin'),
        (_) async => throw Exception('sem plugin'),
        httpClient: _nominatim([
          {
            'lat': '-22.9',
            'lon': '-43.2',
            'address': {'state': 'Rio de Janeiro', 'city': 'Rio de Janeiro'},
          },
        ]),
      );
      await expectLater(
        service.resolve('Copacabana'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Nominatim sem resultado vira "endereço não encontrado"', () async {
      final service = AddressGeocodingService.forTesting(
        (_) async => throw Exception('sem plugin'),
        (_) async => throw Exception('sem plugin'),
        httpClient: _nominatim(const []),
      );
      await expectLater(
        service.resolve('endereço inexistente'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('não encontrado'),
          ),
        ),
      );
    });
  });
}
