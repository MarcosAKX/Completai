// Página pública de avaliações e cursor estável para a próxima consulta.
import 'station_review.dart';

class StationReviewCursor {
  const StationReviewCursor({required this.createdAt});

  final DateTime createdAt;
}

class StationReviewPage {
  const StationReviewPage({
    required this.reviews,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<StationReview> reviews;
  final StationReviewCursor? nextCursor;
  final bool hasMore;
}
