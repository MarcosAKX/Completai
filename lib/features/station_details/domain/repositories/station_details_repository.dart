// Contrato do perfil público do posto, independente de Firebase e plugins.
import '../../../../shared/models/report_reason.dart';
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

  /// Denuncia a avaliação de OUTRO cliente. O uid de quem denuncia vem da
  /// sessão, nunca da tela — senão daria para denunciar em nome de terceiro.
  Future<void> reportReview({
    required String stationUid,
    required String clientUid,
    required ReportReason reason,
  });

  Future<void> openDirections(StationDetails details);
}
