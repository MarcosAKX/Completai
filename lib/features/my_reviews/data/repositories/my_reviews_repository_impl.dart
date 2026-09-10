// Cache por conta e cursor, com falhas traduzidas para o domínio.
import '../../../../core/errors/failure_mapper.dart';
import '../../domain/models/my_review.dart';
import '../../domain/repositories/my_reviews_repository.dart';
import '../services/my_reviews_service.dart';

class MyReviewsRepositoryImpl implements MyReviewsRepository {
  MyReviewsRepositoryImpl(this.service);
  final MyReviewsService service;
  final Map<(String, String?, int?, int?), MyReviewsPageData> _cache = {};
  @override
  Future<MyReviewsPageData> load(
    String uid, {
    MyReviewsCursor? after,
    bool forceRefresh = false,
  }) => guardInfra(() async {
    if (forceRefresh) _cache.removeWhere((key, _) => key.$1 == uid);
    final key = (uid, after?.path, after?.seconds, after?.nanoseconds);
    return _cache[key] ??= await service.load(uid, after: after);
  });
}
