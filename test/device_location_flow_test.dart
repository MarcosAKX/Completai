// Fluxo de GPS e cache do Repository sem localização real ou rede externa.
import 'dart:convert';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/station_discovery/data/repositories/station_discovery_repository_impl.dart';
import 'package:completai/features/station_discovery/data/services/city_geocoding_service.dart';
import 'package:completai/features/station_discovery/data/services/device_location_service.dart';
import 'package:completai/features/station_discovery/data/services/public_station_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Locator extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.whileInUse;
  bool enabled = true;
  int reads = 0;
  double latitude = -20.94;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async => permission;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    reads++;
    return Position(
      latitude: latitude,
      longitude: -48.48,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late _Locator locator;
  late StationDiscoveryRepositoryImpl repository;
  late int requests;
  setUp(() {
    locator = _Locator();
    requests = 0;
    final geocoding = CityGeocodingService(
      useNative: false,
      client: MockClient((_) async {
        requests++;
        return http.Response(
          jsonEncode({
            'countryCode': 'BR',
            'principalSubdivisionCode': 'BR-SP',
            'city': requests == 1 ? 'Bebedouro' : 'Campinas',
          }),
          200,
        );
      }),
    );
    repository = StationDiscoveryRepositoryImpl(
      DeviceLocationService(geocoding, locator: locator),
      PublicStationService(FakeFirebaseFirestore()),
    );
  });
  for (final permission in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
  ]) {
    test(
      'permissão $permission não envia coordenadas; escolha manual funciona',
      () async {
        locator.permission = permission;
        await expectLater(
          repository.loadCurrentCity(),
          throwsA(isA<PermissionFailure>()),
        );
        expect(requests, 0);
        expect(locator.reads, 0);
        expect((await repository.loadCity('Bebedouro')).city, 'Bebedouro');
      },
    );
  }
  test('GPS desligado não faz HTTP', () async {
    locator.enabled = false;
    await expectLater(
      repository.loadCurrentCity(),
      throwsA(isA<LocationFailure>()),
    );
    expect(requests, 0);
  });
  test(
    'mesma coordenada usa cache, mas nova posição resolve nova cidade',
    () async {
      expect((await repository.loadCurrentCity()).city, 'Bebedouro');
      expect(
        (await repository.loadCurrentCity(forceRefresh: true)).city,
        'Bebedouro',
      );
      expect(locator.reads, 2);
      expect(requests, 1);
      locator.latitude = -22.9;
      expect(
        (await repository.loadCurrentCity(forceRefresh: true)).city,
        'Campinas',
      );
      expect(requests, 2);
    },
  );
  test('atualizações simultâneas compartilham uma consulta', () async {
    await Future.wait([
      repository.loadCurrentCity(),
      repository.loadCurrentCity(forceRefresh: true),
    ]);
    expect(locator.reads, 1);
    expect(requests, 1);
  });
}
