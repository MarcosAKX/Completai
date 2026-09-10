// Cache por conta/página e tradução de erros de infraestrutura.
import '../../../../core/errors/failure_mapper.dart';
import '../../domain/models/favorites_page.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../services/favorites_service.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this.service);
  final FavoritesService service;
  final Map<(String, String?), FavoritesPageData> _cache = {};
  @override
  Future<FavoritesPageData> load(
    String uid, {
    String? after,
    bool forceRefresh = false,
  }) => guardInfra(() async {
    final key = (uid, after);
    if (forceRefresh) _cache.removeWhere((key, _) => key.$1 == uid);
    if (_cache.containsKey(key)) return _cache[key]!;
    return _cache[key] = await service.load(uid, after: after);
  });
  @override
  Future<void> setFavorite(
    String uid,
    String stationUid, {
    required bool favorite,
  }) => guardInfra(() async {
    await service.setFavorite(uid, stationUid, favorite: favorite);
    _cache.removeWhere((key, _) => key.$1 == uid);
  });
}
