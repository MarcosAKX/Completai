import 'package:completai/features/fuel_discovery_prototype/domain/models/fuel_prototype_station.dart';
import 'package:completai/features/fuel_discovery_prototype/domain/opening_hours.dart';
import 'package:completai/features/fuel_discovery_prototype/presentation/viewmodels/fuel_discovery_prototype_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('horário que atravessa meia-noite permanece aberto', () {
    expect(
      isWithinOpeningHours(
        now: DateTime(2026, 9, 4, 1),
        schedule: const DailyOpeningHours(open: '18:00', close: '02:00'),
      ),
      isTrue,
    );
    expect(
      isWithinOpeningHours(
        now: DateTime(2026, 9, 4, 3),
        schedule: const DailyOpeningHours(open: '18:00', close: '02:00'),
      ),
      isFalse,
    );
  });

  test('busca filtra por nome ou bairro e combustível reordena', () {
    final provider =
        NotifierProvider<
          FuelDiscoveryPrototypeViewModel,
          FuelDiscoveryPrototypeState
        >(FuelDiscoveryPrototypeViewModel.new);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(provider.notifier).search('centro');
    expect(container.read(provider).visibleStations, hasLength(1));

    container.read(provider.notifier).search('');
    container.read(provider.notifier).selectFuel(PrototypeFuel.ethanol);
    final prices = container
        .read(provider)
        .visibleStations
        .map((station) => station.priceFor(PrototypeFuel.ethanol))
        .toList();
    expect(prices, orderedEquals([...prices]..sort()));
  });

  test('gesto percorre combustíveis sem ultrapassar as extremidades', () {
    final provider =
        NotifierProvider<
          FuelDiscoveryPrototypeViewModel,
          FuelDiscoveryPrototypeState
        >(FuelDiscoveryPrototypeViewModel.new);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(provider.notifier);

    notifier.nextFuel();
    expect(container.read(provider).fuel, PrototypeFuel.ethanol);
    notifier.nextFuel();
    notifier.nextFuel();
    expect(container.read(provider).fuel, PrototypeFuel.diesel);

    notifier.previousFuel();
    expect(container.read(provider).fuel, PrototypeFuel.ethanol);
    notifier.previousFuel();
    notifier.previousFuel();
    expect(container.read(provider).fuel, PrototypeFuel.gasoline);
  });
}
