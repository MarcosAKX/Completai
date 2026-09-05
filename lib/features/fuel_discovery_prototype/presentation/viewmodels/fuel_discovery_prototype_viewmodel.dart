// Estado e interações locais do mockup navegável, sem Repository ou Firebase.
import 'package:riverpod/riverpod.dart';

import '../../domain/models/fuel_prototype_station.dart';
import '../../domain/opening_hours.dart';

enum PrototypeScreenState { loaded, loading, locationDenied, empty }

class FuelDiscoveryPrototypeState {
  const FuelDiscoveryPrototypeState({
    required this.stations,
    this.city = 'Bebedouro',
    this.fuel = PrototypeFuel.gasoline,
    this.query = '',
    this.onlyOpen = false,
    this.screenState = PrototypeScreenState.loaded,
  });

  final List<FuelPrototypeStation> stations;
  final String city;
  final PrototypeFuel fuel;
  final String query;
  final bool onlyOpen;
  final PrototypeScreenState screenState;

  List<FuelPrototypeStation> get visibleStations {
    if (screenState == PrototypeScreenState.empty) return const [];
    final normalized = query.trim().toLowerCase();
    final result = stations.where((station) {
      final matchesCity = station.city == city;
      final matchesSearch =
          normalized.isEmpty ||
          station.name.toLowerCase().contains(normalized) ||
          station.neighborhood.toLowerCase().contains(normalized);
      final matchesOpen =
          !onlyOpen ||
          isWithinOpeningHours(
            now: DateTime.now(),
            schedule: station.openingHours,
          );
      return matchesCity && matchesSearch && matchesOpen;
    }).toList();
    result.sort((a, b) => a.priceFor(fuel).compareTo(b.priceFor(fuel)));
    return result;
  }

  double? get priceGap {
    final visible = visibleStations;
    if (visible.length < 2) return null;
    return visible[1].priceFor(fuel) - visible.first.priceFor(fuel);
  }

  FuelDiscoveryPrototypeState copyWith({
    String? city,
    PrototypeFuel? fuel,
    String? query,
    bool? onlyOpen,
    PrototypeScreenState? screenState,
  }) => FuelDiscoveryPrototypeState(
    stations: stations,
    city: city ?? this.city,
    fuel: fuel ?? this.fuel,
    query: query ?? this.query,
    onlyOpen: onlyOpen ?? this.onlyOpen,
    screenState: screenState ?? this.screenState,
  );
}

class FuelDiscoveryPrototypeViewModel
    extends Notifier<FuelDiscoveryPrototypeState> {
  @override
  FuelDiscoveryPrototypeState build() => FuelDiscoveryPrototypeState(
    stations: [
      FuelPrototypeStation(
        name: 'Posto Avenida',
        neighborhood: 'Centro',
        city: 'Bebedouro',
        prices: const {
          PrototypeFuel.gasoline: 5.49,
          PrototypeFuel.ethanol: 3.69,
          PrototypeFuel.diesel: 5.89,
        },
        rating: 4.8,
        reviewCount: 126,
        pricesUpdatedAt: DateTime.now().subtract(const Duration(days: 1)),
        openingHours: const DailyOpeningHours(open: '00:00', close: '00:00'),
      ),
      FuelPrototypeStation(
        name: 'Posto Central',
        neighborhood: 'Jardim São João',
        city: 'Bebedouro',
        prices: const {
          PrototypeFuel.gasoline: 5.59,
          PrototypeFuel.ethanol: 3.75,
          PrototypeFuel.diesel: 5.79,
        },
        rating: 4.5,
        reviewCount: 84,
        pricesUpdatedAt: DateTime.now().subtract(const Duration(days: 2)),
        openingHours: const DailyOpeningHours(open: '08:00', close: '18:00'),
      ),
      FuelPrototypeStation(
        name: 'Posto Norte',
        neighborhood: 'Residencial Furquim',
        city: 'Bebedouro',
        prices: const {
          PrototypeFuel.gasoline: 5.65,
          PrototypeFuel.ethanol: 3.59,
          PrototypeFuel.diesel: 5.99,
        },
        rating: 4.7,
        reviewCount: 51,
        pricesUpdatedAt: DateTime.now().subtract(const Duration(days: 3)),
        openingHours: const DailyOpeningHours(open: '18:00', close: '02:00'),
      ),
      FuelPrototypeStation(
        name: 'Posto Campinas Sul',
        neighborhood: 'Cambuí',
        city: 'Campinas',
        prices: const {
          PrototypeFuel.gasoline: 5.72,
          PrototypeFuel.ethanol: 3.82,
          PrototypeFuel.diesel: 6.02,
        },
        rating: 4.6,
        reviewCount: 93,
        pricesUpdatedAt: DateTime.now(),
        openingHours: const DailyOpeningHours(open: '00:00', close: '00:00'),
      ),
    ],
  );

  void search(String value) => state = state.copyWith(query: value);
  void selectFuel(PrototypeFuel value) => state = state.copyWith(fuel: value);
  void nextFuel() {
    final index = PrototypeFuel.values.indexOf(state.fuel);
    if (index < PrototypeFuel.values.length - 1) {
      selectFuel(PrototypeFuel.values[index + 1]);
    }
  }

  void previousFuel() {
    final index = PrototypeFuel.values.indexOf(state.fuel);
    if (index > 0) selectFuel(PrototypeFuel.values[index - 1]);
  }

  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    state = state.copyWith();
  }

  void toggleOnlyOpen(bool value) => state = state.copyWith(onlyOpen: value);
  void selectCity(String value) => state = state.copyWith(
    city: value,
    query: '',
    screenState: PrototypeScreenState.loaded,
  );
  void simulate(PrototypeScreenState value) =>
      state = state.copyWith(screenState: value);
}
