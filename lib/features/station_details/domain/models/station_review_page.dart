// Página pública de avaliações e cursor estável para a próxima consulta.
import 'station_review.dart';

class StationReviewCursor {
  const StationReviewCursor({
    required this.seconds,
    required this.nanoseconds,
    required this.documentId,
  });

  // Preserva a precisão do Firestore sem acoplar o domínio ao SDK.
  final int seconds;
  final int nanoseconds;
  final String documentId;
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
