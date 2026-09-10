// Histórico pessoal: uma avaliação por posto, com dados públicos opcionais.
import '../../../station_details/domain/models/station_details.dart';

class MyReview {
  const MyReview({
    required this.stationUid,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.station,
  });
  final String stationUid;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final StationDetails? station;
}

class MyReviewsCursor {
  const MyReviewsCursor({
    required this.seconds,
    required this.nanoseconds,
    required this.path,
  });
  final int seconds;
  final int nanoseconds;
  final String path;
}

class MyReviewsPageData {
  const MyReviewsPageData({
    required this.reviews,
    this.cursor,
    this.hasMore = false,
  });
  final List<MyReview> reviews;
  final MyReviewsCursor? cursor;
  final bool hasMore;
}
