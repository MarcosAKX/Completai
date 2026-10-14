// Estado imutável apresentado pela tela pública do posto.
import 'station_details.dart';
import 'station_review.dart';

class StationDetailsState {
  const StationDetailsState({
    required this.details,
    required this.reviews,
    required this.isFavorite,
    this.hasReviewed = false,
  });

  final StationDetails details;
  final List<StationReview> reviews;
  final bool isFavorite;

  /// O cliente logado já avaliou este posto. Avaliação é única e definitiva:
  /// a tela esconde o botão e o serviço recusa a segunda escrita.
  final bool hasReviewed;

  StationDetailsState copyWith({
    StationDetails? details,
    List<StationReview>? reviews,
    bool? isFavorite,
    bool? hasReviewed,
  }) => StationDetailsState(
    details: details ?? this.details,
    reviews: reviews ?? this.reviews,
    isFavorite: isFavorite ?? this.isFavorite,
    hasReviewed: hasReviewed ?? this.hasReviewed,
  );
}
