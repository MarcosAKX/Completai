// Estado paginado da tela que lista todas as avaliações do posto.
import 'station_review.dart';
import 'station_review_page.dart';

class StationReviewsState {
  const StationReviewsState({
    required this.reviews,
    required this.nextCursor,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<StationReview> reviews;
  final StationReviewCursor? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  StationReviewsState copyWith({
    List<StationReview>? reviews,
    StationReviewCursor? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) => StationReviewsState(
    reviews: reviews ?? this.reviews,
    nextCursor: nextCursor ?? this.nextCursor,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}
