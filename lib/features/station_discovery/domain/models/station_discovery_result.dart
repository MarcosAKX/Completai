// Resultado da descoberta associado à localização usada na consulta.
import 'station_summary.dart';

class StationDiscoveryResult {
  const StationDiscoveryResult({required this.city, required this.stations});
  final String city;
  final List<StationSummary> stations;
}
