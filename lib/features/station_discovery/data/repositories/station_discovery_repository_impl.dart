// Coordena localização, consulta e distância, traduzindo erros técnicos.
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/city_search_key.dart';
import '../../domain/models/station_discovery_result.dart';
import '../../domain/models/station_summary.dart';
import '../../domain/repositories/station_discovery_repository.dart';
import '../services/device_location_service.dart';
import '../services/public_station_service.dart';

class StationDiscoveryRepositoryImpl implements StationDiscoveryRepository {
  StationDiscoveryRepositoryImpl(this._location, this._stations);

  final DeviceLocationService _location;
  final PublicStationService _stations;

  final Map<String, List<StationSummary>> _cache = {};
  DetectedLocation? _lastLocation;
  DateTime? _locationResolvedAt;
  Future<StationDiscoveryResult>? _pendingCurrent;

  @override
  Future<StationDiscoveryResult> loadCurrentCity({bool forceRefresh = false}) =>
      _pendingCurrent ??= _loadCurrentCity(forceRefresh).whenComplete(() {
        _pendingCurrent = null;
      });

  Future<StationDiscoveryResult> _loadCurrentCity(bool forceRefresh) async {
    try {
      final position = await _location.currentPosition();
      final cached = _lastLocation;
      // Reutiliza só a mesma coordenada exata, por até 5 minutos.
      // Não arredonda: proximidade não garante estar no mesmo município.
      final canReuse =
          cached != null &&
          cached.latitude == position.latitude &&
          cached.longitude == position.longitude &&
          _locationResolvedAt != null &&
          DateTime.now().difference(_locationResolvedAt!) <
              const Duration(minutes: 5);
      final location = canReuse ? cached : await _location.resolve(position);
      if (!canReuse) {
        _lastLocation = location;
        _locationResolvedAt = DateTime.now();
      }

      final stations = await _load(location.citySearchKey, forceRefresh);

      return StationDiscoveryResult(
        city: location.city,
        stations: stations
            .map(
              (station) => station.withDistance(
                Geolocator.distanceBetween(
                      location.latitude,
                      location.longitude,
                      station.latitude,
                      station.longitude,
                    ) /
                    1000,
              ),
            )
            .toList(),
      );
    } on LocationPermissionException catch (error) {
      throw PermissionFailure(error.message, cause: error);
    } on AppException catch (error) {
      throw LocationFailure(error.message, cause: error);
    } catch (error) {
      throw UnexpectedFailure(
        'Não foi possível carregar os postos.',
        cause: error,
      );
    }
  }

  @override
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  }) async {
    try {
      final trimmed = city.trim();

      if (trimmed.isEmpty) {
        throw const ValidationFailure('Informe uma cidade.');
      }

      return StationDiscoveryResult(
        city: trimmed,
        stations: await _load(citySearchKey(trimmed), forceRefresh),
      );
    } on Failure {
      rethrow;
    } catch (error) {
      throw UnexpectedFailure(
        'Não foi possível carregar os postos.',
        cause: error,
      );
    }
  }

  Future<List<StationSummary>> _load(String key, bool refresh) async {
    if (!refresh && _cache[key] != null) {
      return _cache[key]!;
    }

    final value = await _stations.fetchByCityKey(key);

    _cache[key] = value;

    return value;
  }
}
