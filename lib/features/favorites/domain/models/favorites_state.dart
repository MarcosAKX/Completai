// Estado da lista e busca local, independente de Flutter.
import '../../../station_details/domain/models/station_details.dart';

class FavoritesState {
  const FavoritesState({
    required this.stations,
    this.cursor,
    this.hasMore = false,
    this.search = '',
  });
  final List<StationDetails> stations;
  final String? cursor;
  final bool hasMore;
  final String search;
  List<StationDetails> get visible {
    final query = search.trim().toLowerCase();
    return stations
        .where(
          (s) => '${s.name} ${s.neighborhood} ${s.city}'.toLowerCase().contains(
            query,
          ),
        )
        .toList();
  }

  FavoritesState withSearch(String value) => FavoritesState(
    stations: stations,
    cursor: cursor,
    hasMore: hasMore,
    search: value,
  );
}
