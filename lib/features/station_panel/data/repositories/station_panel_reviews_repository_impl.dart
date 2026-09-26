// Delega a leitura paginada e a denúncia ao `StationDetailsService` — mesma
// coleção pública (`public_stations/{uid}/reviews`), sem duplicar a lógica
// de cursor já testada em `station_details`.
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../station_details/data/services/station_details_service.dart';
import '../../../station_details/domain/models/station_review_page.dart';
import '../../domain/repositories/station_panel_reviews_repository.dart';

class StationPanelReviewsRepositoryImpl
    implements StationPanelReviewsRepository {
  StationPanelReviewsRepositoryImpl(this._service, {required this.uidProvider});

  final StationDetailsService _service;
  final String? Function() uidProvider;

  String _requireUid() =>
      uidProvider() ?? (throw const UnauthenticatedException());

  @override
  Future<StationReviewPage> loadReviews(
    String stationUid, {
    StationReviewCursor? after,
    int limit = 20,
  }) => guardInfra(
    () => _service.readReviewPage(stationUid, after: after, limit: limit),
  );

  @override
  Future<void> reportReview({
    required String stationUid,
    required String clientUid,
    required String reason,
  }) {
    final reporterUid = _requireUid();
    return guardInfra(
      () => _service.reportReview(
        stationUid: stationUid,
        clientUid: clientUid,
        reporterUid: reporterUid,
        reason: reason,
      ),
    );
  }
}
