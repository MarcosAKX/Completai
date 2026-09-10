// Página de postos salvos; cursor estável pelo identificador do posto.
import '../../../station_details/domain/models/station_details.dart';

class FavoritesPageData {
  const FavoritesPageData({
    required this.stations,
    required this.cursor,
    required this.hasMore,
  });
  final List<StationDetails> stations;
  final String? cursor;
  final bool hasMore;
}
