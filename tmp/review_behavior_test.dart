// Reproduções de auditoria; documentam o comportamento atual sem alterar o app.
import 'package:completai/features/station_discovery/domain/models/station_discovery_result.dart';
import 'package:completai/features/station_discovery/domain/repositories/station_discovery_repository.dart';
import 'package:completai/features/station_discovery/domain/station_opening_hours.dart';
import 'package:completai/features/station_discovery/presentation/providers/station_discovery_providers.dart';
import 'package:completai/features/station_details/domain/models/station_details.dart';
import 'package:completai/shared/models/station_hours_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class AuditRepository implements StationDiscoveryRepository {
  @override
  Future<StationDiscoveryResult> loadCurrentCity({bool forceRefresh = false}) async =>
      const StationDiscoveryResult(city: 'Ribeirão Preto', stations: []);
  @override
  Future<StationDiscoveryResult> loadCity(String city, {bool forceRefresh = false}) async =>
      StationDiscoveryResult(city: city, stations: []);
}

void main() {
  test('reproduz refresh sobrescrevendo cidade manual', () async {
    final container = ProviderContainer(overrides: [
      stationDiscoveryRepositoryProvider.overrideWithValue(AuditRepository()),
    ]);
    addTearDown(container.dispose);
    await container.read(stationDiscoveryViewModelProvider.future);
    final vm = container.read(stationDiscoveryViewModelProvider.notifier);
    await vm.selectCity('Bebedouro');
    expect(container.read(stationDiscoveryViewModelProvider).requireValue.city, 'Bebedouro');
    await vm.refresh();
    expect(container.read(stationDiscoveryViewModelProvider).requireValue.city, 'Ribeirão Preto');
  });

  test('reproduz divergência home versus detalhe na madrugada', () {
    final now = DateTime(2026, 9, 8, 1); // Terça 01h, turno de segunda ainda aberto.
    expect(stationHoursStatus(now, {
      'monday': const StationOpeningPeriod(open: '18:00', close: '02:00'),
      'tuesday': null,
    }).isOpen, isTrue);
    // A Home só recebe todayHours (terça=null), perdendo o turno de segunda.
    expect(isStationOpen(now, {}), isFalse);
  });
}
