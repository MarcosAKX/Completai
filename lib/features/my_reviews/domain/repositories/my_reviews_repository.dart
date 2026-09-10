// Contrato de consulta paginada por conta, sem tipos Firebase.
import '../models/my_review.dart';

abstract interface class MyReviewsRepository {
  Future<MyReviewsPageData> load(
    String uid, {
    MyReviewsCursor? after,
    bool forceRefresh = false,
  });
}
