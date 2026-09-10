// Contrato da lista privada; alterações são aplicadas somente após confirmação.
import '../models/favorites_page.dart';

abstract interface class FavoritesRepository {
  Future<FavoritesPageData> load(
    String uid, {
    String? after,
    bool forceRefresh = false,
  });
  Future<void> setFavorite(
    String uid,
    String stationUid, {
    required bool favorite,
  });
}
