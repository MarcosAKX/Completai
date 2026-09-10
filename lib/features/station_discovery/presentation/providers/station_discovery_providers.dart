// Centraliza as dependências da descoberta de postos para permitir substituição em testes.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/services/city_geocoding_service.dart';
import '../../data/repositories/station_discovery_repository_impl.dart';
import '../../data/services/device_location_service.dart';
import '../../data/services/public_station_service.dart';
import '../../domain/repositories/station_discovery_repository.dart';
import '../viewmodels/station_discovery_viewmodel.dart';

final stationDiscoveryRepositoryProvider = Provider<StationDiscoveryRepository>(
  (ref) {
    final client = http.Client();
    ref.onDispose(client.close);
    return StationDiscoveryRepositoryImpl(
      DeviceLocationService(CityGeocodingService(client: client)),
      PublicStationService(FirebaseFirestore.instance),
    );
  },
);
final stationDiscoveryViewModelProvider =
    AsyncNotifierProvider<StationDiscoveryViewModel, StationDiscoveryState>(
      () => StationDiscoveryViewModel(stationDiscoveryRepositoryProvider),
    );
