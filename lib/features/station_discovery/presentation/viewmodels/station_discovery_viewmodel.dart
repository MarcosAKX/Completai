// Mantém filtros, ordenação e seleção;
// delega GPS e Firestore exclusivamente ao Repository.
import 'package:riverpod/riverpod.dart';

import '../../domain/models/station_discovery_result.dart';
import '../../domain/models/station_summary.dart';
import '../../domain/repositories/station_discovery_repository.dart';
import '../../domain/station_opening_hours.dart';

/// Define como a lista de postos será ordenada.
///
/// Isso pertence à camada de apresentação porque não altera
/// os dados do posto, apenas a forma como eles são apresentados.
enum StationSortMode { lowestPrice, nearest, bestRating }

/// Usado pelo copyWith para diferenciar:
///
/// maximumDistanceKm não informado
///
/// de:
///
/// maximumDistanceKm: null
///
/// Isso é necessário porque null significa "qualquer distância".
const _notProvided = Object();

class StationDiscoveryState {
  const StationDiscoveryState({
    required this.city,
    required this.stations,
    this.fuel = FuelType.gasoline,
    this.search = '',
    this.onlyOpen = false,
    this.minimumRating = 0,
    this.maximumDistanceKm,
    this.sortMode = StationSortMode.lowestPrice,
  });

  final String city;
  final List<StationSummary> stations;

  final FuelType fuel;

  final String search;

  final bool onlyOpen;

  final double minimumRating;

  /// null significa que não existe limite de distância.
  final double? maximumDistanceKm;

  final StationSortMode sortMode;

  /// Quantidade de filtros que realmente removem postos da lista.
  ///
  /// A ordenação não entra nessa contagem porque ela apenas
  /// muda a posição dos postos.
  int get activeFilterCount {
    var count = 0;

    if (minimumRating > 0) {
      count++;
    }

    if (maximumDistanceKm != null) {
      count++;
    }

    if (onlyOpen) {
      count++;
    }

    return count;
  }

  List<StationSummary> get visibleStations {
    final query = search.trim().toLowerCase();
    final now = DateTime.now();

    final result = stations.where((station) {
      //
      // Busca textual.
      //
      final matchesSearch =
          query.isEmpty ||
          station.name.toLowerCase().contains(query) ||
          station.neighborhood.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      //
      // Somente postos abertos.
      //
      if (onlyOpen && !isStationOpen(now, station.openingHours)) {
        return false;
      }

      //
      // Avaliação mínima.
      //
      if (station.averageRating < minimumRating) {
        return false;
      }

      //
      // Distância máxima.
      //
      if (maximumDistanceKm != null) {
        final distance = station.distanceKm;

        // Se o usuário escolheu um limite de distância
        // e o posto não possui distância calculada,
        // ele não pode ser considerado dentro do limite.
        if (distance == null || distance > maximumDistanceKm!) {
          return false;
        }
      }

      return true;
    }).toList();

    //
    // Ordenação.
    //
    result.sort((a, b) {
      return switch (sortMode) {
        StationSortMode.lowestPrice => _compareByLowestPrice(a, b),
        StationSortMode.nearest => _compareByNearest(a, b),
        StationSortMode.bestRating => _compareByBestRating(a, b),
      };
    });

    return result;
  }

  int _compareByLowestPrice(StationSummary a, StationSummary b) {
    final priceComparison = (a.priceFor(fuel) ?? double.infinity).compareTo(
      b.priceFor(fuel) ?? double.infinity,
    );

    if (priceComparison != 0) {
      return priceComparison;
    }

    // Em caso de preços iguais, o posto mais próximo aparece primeiro.
    return (a.distanceKm ?? double.infinity).compareTo(
      b.distanceKm ?? double.infinity,
    );
  }

  int _compareByNearest(StationSummary a, StationSummary b) {
    final distanceComparison = (a.distanceKm ?? double.infinity).compareTo(
      b.distanceKm ?? double.infinity,
    );

    if (distanceComparison != 0) {
      return distanceComparison;
    }

    // Em caso de distância igual, prioriza o menor preço.
    return (a.priceFor(fuel) ?? double.infinity).compareTo(
      b.priceFor(fuel) ?? double.infinity,
    );
  }

  int _compareByBestRating(StationSummary a, StationSummary b) {
    // A maior avaliação vem primeiro.
    final ratingComparison = b.averageRating.compareTo(a.averageRating);

    if (ratingComparison != 0) {
      return ratingComparison;
    }

    // Em caso de avaliação igual, prioriza o mais próximo.
    return (a.distanceKm ?? double.infinity).compareTo(
      b.distanceKm ?? double.infinity,
    );
  }

  StationDiscoveryState copyWith({
    String? city,
    List<StationSummary>? stations,
    FuelType? fuel,
    String? search,
    bool? onlyOpen,
    double? minimumRating,
    Object? maximumDistanceKm = _notProvided,
    StationSortMode? sortMode,
  }) {
    return StationDiscoveryState(
      city: city ?? this.city,
      stations: stations ?? this.stations,
      fuel: fuel ?? this.fuel,
      search: search ?? this.search,
      onlyOpen: onlyOpen ?? this.onlyOpen,
      minimumRating: minimumRating ?? this.minimumRating,

      // Permite enviar null de propósito para remover
      // o filtro de distância.
      maximumDistanceKm: identical(maximumDistanceKm, _notProvided)
          ? this.maximumDistanceKm
          : maximumDistanceKm as double?,

      sortMode: sortMode ?? this.sortMode,
    );
  }
}

class StationDiscoveryViewModel extends AsyncNotifier<StationDiscoveryState> {
  StationDiscoveryViewModel(this._repositoryProvider);

  final ProviderListenable<StationDiscoveryRepository> _repositoryProvider;

  // null representa a descoberta automática; texto representa escolha manual.
  String? _manualCity;

  StationDiscoveryRepository get _repository {
    return ref.read(_repositoryProvider);
  }

  @override
  Future<StationDiscoveryState> build() async {
    _manualCity = null;
    return _from(await _repository.loadCurrentCity());
  }

  StationDiscoveryState _from(
    StationDiscoveryResult value, [
    StationDiscoveryState? previous,
  ]) {
    return StationDiscoveryState(
      city: value.city,
      stations: value.stations,

      // Preserva as escolhas do usuário durante refresh
      // e troca manual de cidade.
      fuel: previous?.fuel ?? FuelType.gasoline,
      search: previous?.search ?? '',
      onlyOpen: previous?.onlyOpen ?? false,
      minimumRating: previous?.minimumRating ?? 0,
      maximumDistanceKm: previous?.maximumDistanceKm,
      sortMode: previous?.sortMode ?? StationSortMode.lowestPrice,
    );
  }

  void selectFuel(FuelType fuel) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(fuel: fuel));
  }

  void nextFuel() {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    if (current.fuel.index < FuelType.values.length - 1) {
      selectFuel(FuelType.values[current.fuel.index + 1]);
    }
  }

  void previousFuel() {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    if (current.fuel.index > 0) {
      selectFuel(FuelType.values[current.fuel.index - 1]);
    }
  }

  void setSearch(String value) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(search: value));
  }

  void toggleOnlyOpen(bool value) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(onlyOpen: value));
  }

  void setMinimumRating(double value) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(minimumRating: value));
  }

  /// Define a distância máxima.
  ///
  /// Exemplos:
  ///
  /// setMaximumDistance(2)
  /// setMaximumDistance(5)
  /// setMaximumDistance(10)
  ///
  /// null significa "qualquer distância".
  void setMaximumDistance(double? value) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(maximumDistanceKm: value));
  }

  void setSortMode(StationSortMode value) {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(sortMode: value));
  }

  /// Remove somente os filtros.
  ///
  /// Não altera combustível, busca, cidade ou ordenação.
  void clearFilters() {
    final current = state.valueOrNull;

    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        onlyOpen: false,
        minimumRating: 0,
        maximumDistanceKm: null,
      ),
    );
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    final manualCity = _manualCity;

    final result = await AsyncValue.guard(() async {
      return _from(
        manualCity == null
            ? await _repository.loadCurrentCity(forceRefresh: true)
            : await _repository.loadCity(manualCity, forceRefresh: true),
        previous,
      );
    });
    // Mantém as escolhas para uma nova tentativa caso a atualização falhe.
    state = result.hasError && previous != null
        ? result.copyWithPrevious(AsyncData(previous))
        : result;
  }

  Future<void> selectCity(String city) async {
    final previous = state.valueOrNull;
    _manualCity = city.trim();

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return _from(await _repository.loadCity(_manualCity!), previous);
    });
  }
}
