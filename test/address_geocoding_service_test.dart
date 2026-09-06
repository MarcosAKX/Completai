// Garante que UF vem do placemark e que endereço fora de SP falha antes da escrita.
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/shared/services/address_geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  Future<List<Location>> location(String _) async => [
    Location(latitude: -23.55, longitude: -46.63, timestamp: DateTime(2026)),
  ];

  test('aceita São Paulo e normaliza state para SP', () async {
    final service = AddressGeocodingService.forTesting(
      location,
      (_) async => [
        Placemark(administrativeArea: 'São Paulo', locality: 'São Paulo'),
      ],
    );
    final result = await service.resolve('Avenida Paulista, São Paulo, Brasil');
    expect(result.state, 'SP');
    expect(result.latitude, -23.55);
    expect(result.city, 'São Paulo');
    expect(result.citySearchKey, 'sao paulo');
  });

  test('rejeita endereço geocodificado fora de SP', () async {
    final service = AddressGeocodingService.forTesting(
      location,
      (_) async => [Placemark(administrativeArea: 'RJ')],
    );
    await expectLater(
      service.resolve('Copacabana, Rio de Janeiro, Brasil'),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          'Cadastro disponível apenas para postos no estado de São Paulo.',
        ),
      ),
    );
  });

  test('rejeita resultado sem estado', () async {
    final service = AddressGeocodingService.forTesting(
      location,
      (_) async => [Placemark()],
    );
    await expectLater(
      service.resolve('Endereço desconhecido'),
      throwsA(isA<ValidationException>()),
    );
  });
}
