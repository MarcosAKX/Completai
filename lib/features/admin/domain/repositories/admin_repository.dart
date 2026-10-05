// Contrato da tela de admin, independente do SDK do Firebase.
import '../models/admin_stations_state.dart';
import '../models/review_report.dart';
import '../../../../shared/models/station_approval_status.dart';

abstract interface class AdminRepository {
  /// Fila de pendentes + já listados. `forceRefresh` ignora o cache.
  Future<AdminStationsState> loadStations({bool forceRefresh = false});

  /// Aprova ou recusa. As rules só aceitam esta escrita de um admin, e só
  /// deixam mudar `status`.
  Future<void> setStationStatus(String uid, StationApprovalStatus status);

  Future<ReviewReportPage> loadReports({
    ReviewReportCursor? after,
    int limit = 20,
  });

  /// Marca a denúncia como analisada sem mexer na avaliação.
  Future<void> dismissReport(ReviewReport report);

  /// Apaga a avaliação denunciada e corrige `averageRating`/`reviewCount`
  /// do posto, marcando a denúncia como resolvida.
  Future<void> removeReportedReview(ReviewReport report);
}
