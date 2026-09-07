// Valida ordenação, filtros e navegação limitada de combustível no ViewModel.
import 'package:completai/features/station_discovery/domain/models/station_discovery_result.dart';
import 'package:completai/features/station_discovery/domain/models/station_summary.dart';
import 'package:completai/features/station_discovery/domain/repositories/station_discovery_repository.dart';
import 'package:completai/features/station_discovery/presentation/providers/station_discovery_providers.dart';
import 'package:completai/features/station_discovery/presentation/viewmodels/station_discovery_viewmodel.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDiscoveryRepository implements StationDiscoveryRepository {
  int refreshes = 0;

  @override
  Future<StationDiscoveryResult> loadCurrentCity({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      refreshes++;
    }

    return const StationDiscoveryResult(
      city: 'Bebedouro',
      stations: [_cheap, _near, _bestRated],
    );
  }

  @override
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  }) async {
    return const StationDiscoveryResult(
      city: 'Bebedouro',
      stations: [_cheap, _near, _bestRated],
    );
  }

  @override
  Future<List<String>> loadAvailableCities({bool forceRefresh = false}) async {
    return const ['Bebedouro'];
  }
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
  todayHours: DailyHours(open: '00:00', close: '23:59'),
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
  averageRating: 4.5,
  reviewCount: 3,
  pricesUpdatedAt: null,
  todayHours: null,
  distanceKm: 1,
);

const _bestRated = StationSummary(
  uid: '3',
  name: 'Posto Melhor Avaliado',
  brand: StationBrand.ipiranga,
  neighborhood: 'Centro',
  city: 'Bebedouro',
  latitude: 0,
  longitude: 0,
  prices: {
    FuelType.gasoline: 5.50,
    FuelType.ethanol: 3.50,
    FuelType.diesel: 6.50,
  },
  averageRating: 5,
  reviewCount: 20,
  pricesUpdatedAt: null,
  todayHours: null,
  distanceKm: 5,
);

void main() {
  ProviderContainer createContainer(FakeDiscoveryRepository repository) {
    final container = ProviderContainer(
      overrides: [
        stationDiscoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    return container;
  }

  test('ordenação padrão continua sendo menor preço', () async {
    final repository = FakeDiscoveryRepository();
    final container = createContainer(repository);

    await container.read(stationDiscoveryViewModelProvider.future);

    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;

    expect(state.sortMode, StationSortMode.lowestPrice);

    expect(state.visibleStations.map((station) => station.uid).toList(), [
      '1',
      '3',
      '2',
    ]);
  });

  test('ordena postos pelo mais próximo', () async {
    final repository = FakeDiscoveryRepository();
    final container = createContainer(repository);

    await container.read(stationDiscoveryViewModelProvider.future);

    final vm = container.read(stationDiscoveryViewModelProvider.notifier);

    vm.setSortMode(StationSortMode.nearest);

    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;

    expect(state.visibleStations.map((station) => station.uid).toList(), [
      '2',
      '1',
      '3',
    ]);
  });

  test('ordena postos pela melhor avaliação', () async {
    final repository = FakeDiscoveryRepository();
    final container = createContainer(repository);

    await container.read(stationDiscoveryViewModelProvider.future);

    final vm = container.read(stationDiscoveryViewModelProvider.notifier);

    vm.setSortMode(StationSortMode.bestRating);

    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;

    expect(state.visibleStations.map((station) => station.uid).toList(), [
      '3',
      '2',
      '1',
    ]);
  });

  test('filtra postos pela distância máxima', () async {
    final repository = FakeDiscoveryRepository();
    final container = createContainer(repository);

    await container.read(stationDiscoveryViewModelProvider.future);

    final vm = container.read(stationDiscoveryViewModelProvider.notifier);

    vm.setMaximumDistance(3);

    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;

    expect(state.maximumDistanceKm, 3);

    expect(state.visibleStations.map((station) => station.uid).toSet(), {
      '1',
      '2',
    });
  });

  test('avaliação mínima continua filtrando corretamente', () async {
    final repository = FakeDiscoveryRepository();
    final container = createContainer(repository);

    await container.read(stationDiscoveryViewModelProvider.future);

    final vm = container.read(stationDiscoveryViewModelProvider.notifier);

    vm.setMinimumRating(4.5);

    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;

    expect(state.visibleStations.map((station) => station.uid).toSet(), {
      '2',
      '3',
    });
  });

  test('contador considera apenas filtros ativos e não a ordenação', () async {
    final repository = FakeDiscoveryRepository();
    final container = createContainer(repository);

    await container.read(stationDiscoveryViewModelProvider.future);

    final vm = container.read(stationDiscoveryViewModelProvider.notifier);

    expect(
      container
          .read(stationDiscoveryViewModelProvider)
          .requireValue
          .activeFilterCount,
      0,
    );

    vm.setMinimumRating(4);
    vm.setMaximumDistance(5);
    vm.toggleOnlyOpen(true);
    vm.setSortMode(StationSortMode.bestRating);

    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;

    expect(state.activeFilterCount, 3);
  });

  test(
    'limpar filtros restaura valores padrão sem alterar combustível',
    () async {
      final repository = FakeDiscoveryRepository();
      final container = createContainer(repository);

      await container.read(stationDiscoveryViewModelProvider.future);

      final vm = container.read(stationDiscoveryViewModelProvider.notifier);

      vm.selectFuel(FuelType.diesel);

      vm.setMinimumRating(4.5);
      vm.setMaximumDistance(2);
      vm.toggleOnlyOpen(true);

      vm.clearFilters();

      final state = container
          .read(stationDiscoveryViewModelProvider)
          .requireValue;

      expect(state.fuel, FuelType.diesel);

      expect(state.minimumRating, 0);

      expect(state.maximumDistanceKm, isNull);

      expect(state.onlyOpen, isFalse);

      expect(state.activeFilterCount, 0);
    },
  );

  test('swipe de combustível continua respeitando os limites', () async {
    final repository = FakeDiscoveryRepository();
    final container = createContainer(repository);

    await container.read(stationDiscoveryViewModelProvider.future);

    final vm = container.read(stationDiscoveryViewModelProvider.notifier);

    vm.nextFuel();

    expect(
      container.read(stationDiscoveryViewModelProvider).requireValue.fuel,
      FuelType.ethanol,
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

  test('pull refresh preserva filtros ordenação e força recarga', () async {
    final repository = FakeDiscoveryRepository();
    final container = createContainer(repository);

    await container.read(stationDiscoveryViewModelProvider.future);

    final vm = container.read(stationDiscoveryViewModelProvider.notifier);

    vm.selectFuel(FuelType.diesel);

    vm.toggleOnlyOpen(true);

    vm.setSearch('barato');

    vm.setMinimumRating(4);

    vm.setMaximumDistance(5);

    vm.setSortMode(StationSortMode.nearest);

    await vm.refresh();

    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;

    expect(state.fuel, FuelType.diesel);

    expect(state.onlyOpen, isTrue);

    expect(state.search, 'barato');

    expect(state.minimumRating, 4);

    expect(state.maximumDistanceKm, 5);

    expect(state.sortMode, StationSortMode.nearest);

    expect(repository.refreshes, 1);
  });
}
