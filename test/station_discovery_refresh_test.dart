// Verifica a origem da cidade e a preservação das escolhas durante a atualização.
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/station_discovery/domain/models/station_discovery_result.dart';
import 'package:completai/features/station_discovery/domain/models/station_summary.dart';
import 'package:completai/features/station_discovery/domain/repositories/station_discovery_repository.dart';
import 'package:completai/features/station_discovery/presentation/providers/station_discovery_providers.dart';
import 'package:completai/features/station_discovery/presentation/viewmodels/station_discovery_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements StationDiscoveryRepository {
  int gpsCalls = 0;
  bool gpsDenied = false;
  bool cityFails = false;
  final cityCalls = <({String city, bool refresh})>[];

  @override
  Future<StationDiscoveryResult> loadCurrentCity({
    bool forceRefresh = false,
  }) async {
    gpsCalls++;
    if (gpsDenied) throw const PermissionFailure('GPS negado');
    return const StationDiscoveryResult(city: 'Ribeirão Preto', stations: []);
  }

  @override
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  }) async {
    cityCalls.add((city: city, refresh: forceRefresh));
    if (cityFails) throw const NetworkFailure('Sem conexão');
    return StationDiscoveryResult(city: city, stations: []);
  }
}

void main() {
  late _Repository repository;
  late ProviderContainer container;
  setUp(() {
    repository = _Repository();
    container = ProviderContainer(
      overrides: [
        stationDiscoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'atualização manual preserva cidade, filtros e combustível sem GPS',
    () async {
      await container.read(stationDiscoveryViewModelProvider.future);
      final vm = container.read(stationDiscoveryViewModelProvider.notifier);
      await vm.selectCity('Bebedouro');
      vm.selectFuel(FuelType.ethanol);
      vm.setSearch('Centro');
      vm.toggleOnlyOpen(true);
      vm.setMinimumRating(4);
      vm.setMaximumDistance(5);
      vm.setSortMode(StationSortMode.bestRating);
      repository.gpsDenied = true;
      await vm.refresh();
      final state = container
          .read(stationDiscoveryViewModelProvider)
          .requireValue;
      expect(state.city, 'Bebedouro');
      expect(state.fuel, FuelType.ethanol);
      expect(state.search, 'Centro');
      expect(state.onlyOpen, isTrue);
      expect(state.minimumRating, 4);
      expect(state.maximumDistanceKm, 5);
      expect(state.sortMode, StationSortMode.bestRating);
      expect(repository.gpsCalls, 1);
      expect(repository.cityCalls.last, (city: 'Bebedouro', refresh: true));
    },
  );

  test('cidade manual funciona após permissão negada na abertura', () async {
    repository.gpsDenied = true;
    await expectLater(
      container.read(stationDiscoveryViewModelProvider.future),
      throwsA(isA<PermissionFailure>()),
    );
    final vm = container.read(stationDiscoveryViewModelProvider.notifier);
    await vm.selectCity('Bebedouro');
    await vm.refresh();
    expect(
      container.read(stationDiscoveryViewModelProvider).requireValue.city,
      'Bebedouro',
    );
    expect(repository.gpsCalls, 1);
  });

  test('modo automático continua consultando GPS ao atualizar', () async {
    await container.read(stationDiscoveryViewModelProvider.future);
    await container.read(stationDiscoveryViewModelProvider.notifier).refresh();
    expect(repository.gpsCalls, 2);
    expect(repository.cityCalls, isEmpty);
  });

  test('erro de rede e nova tentativa mantêm a seleção manual', () async {
    await container.read(stationDiscoveryViewModelProvider.future);
    final vm = container.read(stationDiscoveryViewModelProvider.notifier);
    await vm.selectCity('Bebedouro');
    vm.selectFuel(FuelType.diesel);
    repository.cityFails = true;
    await vm.refresh();
    expect(container.read(stationDiscoveryViewModelProvider).hasError, isTrue);
    repository.cityFails = false;
    await vm.refresh();
    final state = container
        .read(stationDiscoveryViewModelProvider)
        .requireValue;
    expect(state.city, 'Bebedouro');
    expect(state.fuel, FuelType.diesel);
    expect(repository.gpsCalls, 1);
  });
}
