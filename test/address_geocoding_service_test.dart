// Geocodificação: caminho nativo, validação de SP, busca estruturada e
// fallback HTTP livre (Nominatim).
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

StationAddressInput _input({
  String street = 'Rua Sete',
  String number = '100',
  String neighborhood = 'Centro',
  String city = 'Bebedouro',
  String cep = '14700-000',
}) => StationAddressInput(
  street: street,
  number: number,
  neighborhood: neighborhood,
  city: city,
  cep: cep,
);

/// Client HTTP que falha o teste se for chamado (o caminho nativo bastou).
http.Client get _forbiddenHttp => MockClient((_) async {
  fail('não deveria chamar o Nominatim quando o nativo respondeu');
});

http.Client _nominatim(List<Map<String, dynamic>> results) =>
    MockClient((_) async => http.Response(jsonEncode(results), 200));

void main() {
  group('endereço estruturado', () {
    test('line junta rua e número; sem número fica só a rua', () {
      expect(_input().line, 'Rua Sete, 100');
      expect(_input(number: '').line, 'Rua Sete');
    });

    test('freeForm inclui bairro, cidade e CEP mascarado', () {
      expect(
        _input().freeForm,
        'Rua Sete, 100, Centro, Bebedouro, 14700-000, Brasil',
      );
    });

    test('CEP incompleto não entra na consulta', () {
      final input = _input(cep: '1470');
      expect(input.hasCep, isFalse);
      expect(input.freeForm, 'Rua Sete, 100, Centro, Bebedouro, Brasil');
      expect(input.cepDigits, '1470');
    });

    test('splitLegacyLine separa a linha antiga em rua e número', () {
      expect(
        StationAddressInput.splitLegacyLine('Avenida Brasil, 1000'),
        ('Avenida Brasil', '1000'),
      );
      expect(
        StationAddressInput.splitLegacyLine('Rodovia Anhanguera, s/n'),
        ('Rodovia Anhanguera', 's/n'),
      );
    });

    test('splitLegacyLine não inventa número quando a cauda não é um', () {
      expect(
        StationAddressInput.splitLegacyLine('Avenida Brasil, Centro'),
        ('Avenida Brasil, Centro', ''),
      );
      expect(
        StationAddressInput.splitLegacyLine('Praça da Sé'),
        ('Praça da Sé', ''),
      );
    });
  });

  group('caminho nativo', () {
    test('aceita São Paulo e normaliza state para SP', () async {
      final service = AddressGeocodingService.forTesting(
        _location,
        (_) async => [
          Placemark(administrativeArea: 'São Paulo', locality: 'Campinas'),
        ],
        httpClient: _forbiddenHttp,
      );
      final result = await service.resolve(_input(city: 'Campinas'));
      expect(result.state, 'SP');
      expect(result.city, 'Campinas');
      expect(result.citySearchKey, 'campinas');
      expect(result.latitude, -23.55);
    });

    test('recebe a consulta livre montada a partir das partes', () async {
      String? seen;
      final service = AddressGeocodingService.forTesting((address) async {
        seen = address;
        return [
          Location(
            latitude: -21.0,
            longitude: -48.4,
            timestamp: DateTime(2026),
          ),
        ];
      }, (_) async => [Placemark(administrativeArea: 'SP', locality: 'Bebedouro')], httpClient: _forbiddenHttp);
      await service.resolve(_input());
      expect(seen, 'Rua Sete, 100, Centro, Bebedouro, 14700-000, Brasil');
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
        service.resolve(_input(city: 'Rio de Janeiro')),
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
      final result = await service.resolve(_input());
      expect(result.state, 'SP');
      expect(result.city, 'Bebedouro');
      expect(result.citySearchKey, 'bebedouro');
      expect(result.latitude, closeTo(-21.03, 1e-6));
    });

    test('a primeira tentativa HTTP é estruturada, com CEP', () async {
      final calls = <Uri>[];
      final service = AddressGeocodingService.forTesting(
        (_) async => throw Exception('sem plugin'),
        (_) async => throw Exception('sem plugin'),
        httpClient: MockClient((request) async {
          calls.add(request.url);
          return http.Response(
            jsonEncode([
              {
                'lat': '-21.03',
                'lon': '-48.47',
                'address': {'state': 'São Paulo', 'city': 'Bebedouro'},
              },
            ]),
            200,
          );
        }),
      );
      await service.resolve(_input());

      expect(calls, hasLength(1));
      final params = calls.single.queryParameters;
      expect(params['street'], '100 Rua Sete');
      expect(params['city'], 'Bebedouro');
      expect(params['postalcode'], '14700000');
      expect(params.containsKey('q'), isFalse);
    });

    test('cai para a busca livre quando a estruturada não acha', () async {
      final calls = <Uri>[];
      final service = AddressGeocodingService.forTesting(
        (_) async => throw Exception('sem plugin'),
        (_) async => throw Exception('sem plugin'),
        httpClient: MockClient((request) async {
          calls.add(request.url);
          final isStructured = request.url.queryParameters.containsKey('street');
          return http.Response(
            isStructured
                ? '[]'
                : jsonEncode([
                    {
                      'lat': '-21.03',
                      'lon': '-48.47',
                      'address': {'state': 'São Paulo', 'city': 'Bebedouro'},
                    },
                  ]),
            200,
          );
        }),
      );
      final result = await service.resolve(_input());

      expect(calls, hasLength(2));
      expect(calls.last.queryParameters['q'], contains('Rua Sete, 100'));
      expect(result.city, 'Bebedouro');
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
        service.resolve(_input()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nenhuma tentativa achou vira "endereço não encontrado"', () async {
      final service = AddressGeocodingService.forTesting(
        (_) async => throw Exception('sem plugin'),
        (_) async => throw Exception('sem plugin'),
        httpClient: _nominatim(const []),
      );
      await expectLater(
        service.resolve(_input()),
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
