// Estado imutável apresentado pela tela pública do posto.
import 'station_details.dart';
import 'station_review.dart';

class StationDetailsState {
  const StationDetailsState({
    required this.details,
    required this.reviews,
    required this.isFavorite,
  });

  final StationDetails details;
  final List<StationReview> reviews;
  final bool isFavorite;

  StationDetailsState copyWith({
    StationDetails? details,
    List<StationReview>? reviews,
    bool? isFavorite,
  }) => StationDetailsState(
    details: details ?? this.details,
    reviews: reviews ?? this.reviews,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
