// Coordena paginação, busca e remoção/desfazer sem importar widgets.
import 'package:riverpod/riverpod.dart';
import '../../domain/models/favorites_state.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../../station_details/domain/models/station_details.dart';

class FavoritesViewModel
    extends AutoDisposeFamilyAsyncNotifier<FavoritesState, String> {
  FavoritesViewModel(this.repositoryProvider);
  final ProviderListenable<FavoritesRepository> repositoryProvider;
  late String _uid;
  bool _disposed = false;
  late FavoritesRepository _repository;
  @override
  Future<FavoritesState> build(String arg) async {
    _uid = arg;
    _disposed = false;
    _repository = ref.watch(repositoryProvider);
    ref.onDispose(() => _disposed = true);
    final page = await _repository.load(arg, forceRefresh: true);
    return FavoritesState(
      stations: page.stations,
      cursor: page.cursor,
      hasMore: page.hasMore,
    );
  }

  void search(String value) {
    if (state.isLoading) return;
    final current = state.valueOrNull;
    if (current != null) state = AsyncData(current.withSearch(value));
  }

  Future<bool> refresh() => _run((current) async {
    final page = await _repository.load(_uid, forceRefresh: true);
    return FavoritesState(
      stations: page.stations,
      cursor: page.cursor,
      hasMore: page.hasMore,
      search: current.search,
    );
  });
  Future<bool> loadMore() => _run((current) async {
    if (!current.hasMore || current.cursor == null) return current;
    final page = await _repository.load(_uid, after: current.cursor);
    final entries = {
      for (final s in current.stations) s.uid: s,
      for (final s in page.stations) s.uid: s,
    };
    return FavoritesState(
      stations: entries.values.toList(),
      cursor: page.cursor,
      hasMore: page.hasMore,
      search: current.search,
    );
  });
  Future<bool> remove(StationDetails station) => _run((current) async {
    await _repository.setFavorite(_uid, station.uid, favorite: false);
    return FavoritesState(
      stations: current.stations.where((s) => s.uid != station.uid).toList(),
      cursor: current.cursor,
      hasMore: current.hasMore,
      search: current.search,
    );
  });
  Future<bool> undo(StationDetails station) => _run((current) async {
    await _repository.setFavorite(_uid, station.uid, favorite: true);
    final stations = {
      for (final s in current.stations) s.uid: s,
      station.uid: station,
    }.values.toList()..sort((a, b) => a.uid.compareTo(b.uid));
    return FavoritesState(
      stations: stations,
      cursor: current.cursor,
      hasMore: current.hasMore,
      search: current.search,
    );
  });
  Future<bool> _run(
    Future<FavoritesState> Function(FavoritesState) operation,
  ) async {
    if (state.isLoading || state.valueOrNull == null) return false;
    final previous = state;
    state = const AsyncValue<FavoritesState>.loading().copyWithPrevious(
      previous,
    );
    final result = await AsyncValue.guard(
      () => operation(previous.requireValue),
    );
    if (_disposed) return false;
    final query = state.valueOrNull?.search ?? previous.requireValue.search;
    state = result.hasError
        ? result.copyWithPrevious(previous)
        : AsyncData(result.requireValue.withSearch(query));
    return !result.hasError;
  }
}
