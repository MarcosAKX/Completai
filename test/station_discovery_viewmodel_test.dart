// Valida ordenação, filtros e navegação limitada de combustível no ViewModel.
import 'package:completai/features/station_discovery/domain/models/station_discovery_result.dart';
import 'package:completai/features/station_discovery/domain/models/station_summary.dart';
import 'package:completai/features/station_discovery/domain/repositories/station_discovery_repository.dart';
import 'package:completai/features/station_discovery/presentation/providers/station_discovery_providers.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDiscoveryRepository implements StationDiscoveryRepository {
  int refreshes = 0;
  @override
  Future<StationDiscoveryResult> loadCurrentCity({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) refreshes++;
    return const StationDiscoveryResult(
      city: 'Bebedouro',
      stations: [_cheap, _near],
    );
  }

  @override
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  }) async => StationDiscoveryResult(city: city, stations: const [_cheap]);
}

const _cheap = StationSummary(
  uid: '1',
  name: 'Posto Barato',
  brand: StationBrand.branca,
  neighborhood: 'Centro',
  city: 'Bebedouro',
  latitude: 0,
  longitude: 0,
  prices: {FuelType.gasoline: 5, FuelType.ethanol: 4, FuelType.diesel: 6},
  averageRating: 4,
  reviewCount: 2,
  pricesUpdatedAt: null,
  todayHours: DailyHours(open: '00:00', close: '00:00'),
  distanceKm: 3,
);
const _near = StationSummary(
  uid: '2',
  name: 'Posto Próximo',
  brand: StationBrand.shell,
  neighborhood: 'Jardim',
  city: 'Bebedouro',
  latitude: 0,
  longitude: 0,
  prices: {FuelType.gasoline: 6, FuelType.ethanol: 3, FuelType.diesel: 7},
  averageRating: 5,
  reviewCount: 3,
  pricesUpdatedAt: null,
  todayHours: null,
  distanceKm: 1,
);

void main() {
  test('ordena por combustível e swipe para nos limites', () async {
    final repository = FakeDiscoveryRepository();
    final container = ProviderContainer(
      overrides: [
        stationDiscoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(stationDiscoveryViewModelProvider.future);
    final vm = container.read(stationDiscoveryViewModelProvider.notifier);
    expect(
      container
          .read(stationDiscoveryViewModelProvider)
          .requireValue
          .visibleStations
          .first
          .uid,
      '1',
    );
    vm.nextFuel();
    expect(
      container.read(stationDiscoveryViewModelProvider).requireValue.fuel,
      FuelType.ethanol,
    );
    expect(
      container
          .read(stationDiscoveryViewModelProvider)
          .requireValue
          .visibleStations
          .first
          .uid,
      '2',
    );
    vm.nextFuel();
    vm.nextFuel();
    expect(
      container.read(stationDiscoveryViewModelProvider).requireValue.fuel,
      FuelType.diesel,
    );
    vm.previousFuel();
    expect(
      container.read(stationDiscoveryViewModelProvider).requireValue.fuel,
      FuelType.ethanol,
    );
  });

  test('pull refresh preserva filtros e força recarga', () async {
    final repository = FakeDiscoveryRepository();
    final container = ProviderContainer(
      overrides: [
        stationDiscoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(stationDiscoveryViewModelProvider.future);
    final vm = container.read(stationDiscoveryViewModelProvider.notifier);
    vm.selectFuel(FuelType.diesel);
    vm.toggleOnlyOpen(true);
    vm.setSearch('barato');
    await vm.refresh();
    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;
    expect(
      (state.fuel, state.onlyOpen, state.search, repository.refreshes),
      (FuelType.diesel, true, 'barato', 1),
    );
  });
}
