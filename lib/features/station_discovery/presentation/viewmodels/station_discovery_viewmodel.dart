// Mantém filtros e seleção; delega GPS e Firestore exclusivamente ao Repository.
import 'package:riverpod/riverpod.dart';
import '../../domain/models/station_discovery_result.dart';
import '../../domain/models/station_summary.dart';
import '../../domain/repositories/station_discovery_repository.dart';
import '../../domain/station_opening_hours.dart';

class StationDiscoveryState {
  const StationDiscoveryState({
    required this.city,
    required this.stations,
    this.fuel = FuelType.gasoline,
    this.search = '',
    this.onlyOpen = false,
    this.minimumRating = 0,
  });
  final String city;
  final List<StationSummary> stations;
  final FuelType fuel;
  final String search;
  final bool onlyOpen;
  final double minimumRating;

  List<StationSummary> get visibleStations {
    final query = search.trim().toLowerCase();
    final now = DateTime.now();
    final result = stations
        .where(
          (station) =>
              (query.isEmpty ||
                  station.name.toLowerCase().contains(query) ||
                  station.neighborhood.toLowerCase().contains(query)) &&
              (!onlyOpen || isStationOpen(now, station.todayHours)) &&
              station.averageRating >= minimumRating,
        )
        .toList();
    result.sort((a, b) {
      final price = (a.priceFor(fuel) ?? double.infinity).compareTo(
        b.priceFor(fuel) ?? double.infinity,
      );
      if (price != 0) return price;
      return (a.distanceKm ?? double.infinity).compareTo(
        b.distanceKm ?? double.infinity,
      );
    });
    return result;
  }

  StationDiscoveryState copyWith({
    String? city,
    List<StationSummary>? stations,
    FuelType? fuel,
    String? search,
    bool? onlyOpen,
    double? minimumRating,
  }) => StationDiscoveryState(
    city: city ?? this.city,
    stations: stations ?? this.stations,
    fuel: fuel ?? this.fuel,
    search: search ?? this.search,
    onlyOpen: onlyOpen ?? this.onlyOpen,
    minimumRating: minimumRating ?? this.minimumRating,
  );
}

class StationDiscoveryViewModel extends AsyncNotifier<StationDiscoveryState> {
  StationDiscoveryViewModel(this._repositoryProvider);
  final ProviderListenable<StationDiscoveryRepository> _repositoryProvider;
  StationDiscoveryRepository get _repository => ref.read(_repositoryProvider);
  @override
  Future<StationDiscoveryState> build() async =>
      _from(await _repository.loadCurrentCity());
  StationDiscoveryState _from(
    StationDiscoveryResult value, [
    StationDiscoveryState? previous,
  ]) => StationDiscoveryState(
    city: value.city,
    stations: value.stations,
    fuel: previous?.fuel ?? FuelType.gasoline,
    search: previous?.search ?? '',
    onlyOpen: previous?.onlyOpen ?? false,
    minimumRating: previous?.minimumRating ?? 0,
  );
  void selectFuel(FuelType fuel) =>
      state = AsyncData(state.requireValue.copyWith(fuel: fuel));
  void nextFuel() {
    final s = state.valueOrNull;
    if (s != null && s.fuel.index < 2) {
      selectFuel(FuelType.values[s.fuel.index + 1]);
    }
  }

  void previousFuel() {
    final s = state.valueOrNull;
    if (s != null && s.fuel.index > 0) {
      selectFuel(FuelType.values[s.fuel.index - 1]);
    }
  }

  void setSearch(String value) {
    final s = state.valueOrNull;
    if (s != null) state = AsyncData(s.copyWith(search: value));
  }

  void toggleOnlyOpen(bool value) {
    final s = state.valueOrNull;
    if (s != null) state = AsyncData(s.copyWith(onlyOpen: value));
  }

  void setMinimumRating(double value) {
    final s = state.valueOrNull;
    if (s != null) state = AsyncData(s.copyWith(minimumRating: value));
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = await AsyncValue.guard(
      () async => _from(
        await _repository.loadCurrentCity(forceRefresh: true),
        previous,
      ),
    );
  }

  Future<void> selectCity(String city) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => _from(await _repository.loadCity(city), previous),
    );
  }
}
