// Obtém a posição e deriva a cidade confiável pelo GPS/geocodificação.
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/city_search_key.dart';

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
  Future<DetectedLocation> detect() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException();
    }
    final position = await Geolocator.getCurrentPosition();
    final marks = await Geocoding().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (marks.isEmpty) throw const LocationUnavailableException();
    final mark = marks.first;
    final state = (mark.administrativeArea ?? '').trim().toUpperCase();
    if (state != 'SP' && state != 'SÃO PAULO' && state != 'SAO PAULO') {
      throw const ValidationException(
        'No momento, o CompletAI atende apenas o estado de São Paulo.',
      );
    }
    final city = (mark.locality ?? mark.subAdministrativeArea ?? '').trim();
    if (city.isEmpty) throw const LocationUnavailableException();
    return DetectedLocation(
      city,
      citySearchKey(city),
      position.latitude,
      position.longitude,
    );
  }
}
