// Contrato do perfil público do posto, independente de Firebase e plugins.
import '../models/station_details.dart';
import '../models/station_details_state.dart';
import '../models/station_review_page.dart';

abstract interface class StationDetailsRepository {
  Future<StationDetailsState> load(
    String stationUid, {
    bool forceRefresh = false,
  });

  Future<void> setFavorite(String stationUid, {required bool favorite});

  Future<void> submitReview(
    String stationUid, {
    required int rating,
    required String comment,
  });

  Future<StationReviewPage> loadReviewPage(
    String stationUid, {
    StationReviewCursor? after,
    int limit = 20,
  });

  Future<void> openDirections(StationDetails details);
}
