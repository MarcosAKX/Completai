// Busca sobre páginas carregadas; ordem cronológica vem da consulta.
import 'my_review.dart';

class MyReviewsState {
  const MyReviewsState({
    required this.reviews,
    this.cursor,
    this.hasMore = false,
    this.search = '',
  });
  final List<MyReview> reviews;
  final MyReviewsCursor? cursor;
  final bool hasMore;
  final String search;
  List<MyReview> get visible {
    final query = search.trim().toLowerCase();
    return reviews
        .where(
          (r) =>
              '${r.station?.name ?? 'Posto indisponível'} ${r.station?.neighborhood ?? ''}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
  }

  MyReviewsState withSearch(String value) => MyReviewsState(
    reviews: reviews,
    cursor: cursor,
    hasMore: hasMore,
    search: value,
  );
}
