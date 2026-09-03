// Resolve o endereço uma vez durante o cadastro, sem persistir coordenadas nulas.
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/exceptions.dart';

class StationCoordinates {
  const StationCoordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class AddressGeocodingService {
  Future<StationCoordinates> resolve(String address) async {
    final locations = await Geocoding().locationFromAddress(
      '$address, ${FirestoreCollections.mvpCity}, SP, Brasil',
    );
    if (locations.isEmpty) {
      throw const ValidationException(
        'Endereço não encontrado. Confira o endereço do posto.',
      );
    }
    final location = locations.first;
    if (!location.latitude.isFinite ||
        !location.longitude.isFinite ||
        location.latitude.abs() > 90 ||
        location.longitude.abs() > 180) {
      throw const ValidationException(
        'O endereço retornou coordenadas inválidas.',
      );
    }
    return StationCoordinates(location.latitude, location.longitude);
  }
}
