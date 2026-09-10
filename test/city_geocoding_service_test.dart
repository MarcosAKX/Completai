// Conversão da posição atual: HTTP simulado, sem enviar coordenadas à API real.
import 'dart:async';
import 'dart:convert';
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/features/station_discovery/data/services/city_geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _body = {
  'countryCode': 'BR',
  'principalSubdivisionCode': 'BR-SP',
  'city': 'Bebedouro',
};

void main() {
  test('Web consulta coordenadas atuais e normaliza cidade', () async {
    final service = CityGeocodingService(
      useNative: false,
      client: MockClient((request) async {
        expect(request.url.host, 'api.bigdatacloud.net');
        expect(request.url.queryParameters['latitude'], '-20.94');
        expect(request.url.queryParameters['longitude'], '-48.48');
        return http.Response(jsonEncode(_body), 200);
      }),
    );
    expect((await service.resolve(-20.94, -48.48)).city, 'Bebedouro');
  });

  test('nativo válido evita chamada HTTP', () async {
    final service = CityGeocodingService(
      useNative: true,
      nativeLookup: (_, _) async => [
        Placemark(administrativeArea: 'São Paulo', locality: 'Bebedouro'),
      ],
      client: MockClient((_) async => throw StateError('HTTP não esperado')),
    );
    expect((await service.resolve(-20.94, -48.48)).city, 'Bebedouro');
  });

  test('falha nativa usa alternativa HTTP', () async {
    final service = CityGeocodingService(
      useNative: true,
      nativeLookup: (_, _) async => throw UnsupportedError('Sem geocoder'),
      client: MockClient((_) async => http.Response(jsonEncode(_body), 200)),
    );
    expect((await service.resolve(-20.94, -48.48)).city, 'Bebedouro');
  });

  test(
    'fora de SP nativo é rejeitado sem tentar contornar pelo HTTP',
    () async {
      final service = CityGeocodingService(
        useNative: true,
        nativeLookup: (_, _) async => [
          Placemark(administrativeArea: 'RJ', locality: 'Rio de Janeiro'),
        ],
        client: MockClient((_) async => throw StateError('HTTP não esperado')),
      );
      await expectLater(
        service.resolve(-22.9, -43.2),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  for (final body in [
    {..._body, 'principalSubdivisionCode': 'BR-RJ'},
    {..._body, 'countryCode': 'US'},
    {..._body, 'city': '', 'locality': 'Centro'},
    <String, Object>{},
  ]) {
    test('rejeita UF/município ausente ou incompatível: $body', () async {
      final service = CityGeocodingService(
        useNative: false,
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
      );
      await expectLater(
        service.resolve(-20.94, -48.48),
        throwsA(isA<AppException>()),
      );
    });
  }

  for (final status in [402, 429, 500]) {
    test(
      'HTTP $status permite fallback manual, sem retentativa automática',
      () async {
        var calls = 0;
        final service = CityGeocodingService(
          useNative: false,
          client: MockClient((_) async {
            calls++;
            return http.Response('', status);
          }),
        );
        await expectLater(
          service.resolve(-20.94, -48.48),
          throwsA(isA<LocationUnavailableException>()),
        );
        expect(calls, 1);
      },
    );
  }

  test('timeout e JSON inválido viram exceção tratável', () async {
    for (final client in [
      MockClient((_) => Completer<http.Response>().future),
      MockClient((_) async => http.Response('invalid', 200)),
    ]) {
      final service = CityGeocodingService(
        useNative: false,
        client: client,
        timeout: const Duration(milliseconds: 5),
      );
      await expectLater(
        service.resolve(-20.94, -48.48),
        throwsA(isA<LocationUnavailableException>()),
      );
    }
  });
}
