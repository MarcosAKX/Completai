// Contrato da home do motorista, independente de Firebase e geolocator.
import '../models/station_discovery_result.dart';

abstract interface class StationDiscoveryRepository {
  Future<StationDiscoveryResult> loadCurrentCity({bool forceRefresh = false});
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  });
}
