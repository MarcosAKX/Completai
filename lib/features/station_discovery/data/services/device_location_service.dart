// Obtém a posição e deriva a cidade confiável pelo GPS/geocodificação.
import 'package:geolocator/geolocator.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/city_search_key.dart';
import 'city_geocoding_service.dart';

class DetectedLocation {
  const DetectedLocation(
    this.city,
    this.citySearchKey,
    this.latitude,
    this.longitude,
  );
  final String city;
  final String citySearchKey;
  final double latitude;
  final double longitude;
}

class DeviceLocationService {
  DeviceLocationService(this._geocoding, {GeolocatorPlatform? locator})
    : _locator = locator ?? GeolocatorPlatform.instance;

  final CityGeocodingService _geocoding;
  final GeolocatorPlatform _locator;

  Future<Position> currentPosition() => _position().timeout(
    const Duration(seconds: 20),
    onTimeout: () => throw const LocationUnavailableException(),
  );

  Future<Position> _position() async {
    if (!await _locator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException();
    }
    var permission = await _locator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException();
    }
    return _locator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<DetectedLocation> resolve(Position position) async {
    final city = (await _geocoding.resolve(
      position.latitude,
      position.longitude,
    )).city;
    return DetectedLocation(
      city,
      citySearchKey(city),
      position.latitude,
      position.longitude,
    );
  }
}
