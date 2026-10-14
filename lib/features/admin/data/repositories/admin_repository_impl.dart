// Une os dois services de admin atrás de uma interface, traduzindo erro de
// infra em `Failure` tipada e cacheando só a fila de postos.
import '../../../../core/errors/failure_mapper.dart';
import '../../domain/models/admin_stations_state.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/review_report.dart';
import '../../../../shared/models/station_approval_status.dart';
import '../../domain/repositories/admin_repository.dart';
import '../services/admin_reports_service.dart';
import '../services/admin_stations_service.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._stations, this._reports);

  final AdminStationsService _stations;
  final AdminReportsService _reports;

  /// A fila é relida inteira a cada aprovação, então o cache só evita
  /// recarregar ao trocar de aba. Descartado em qualquer escrita.
  AdminStationsState? _cache;

  @override
  Future<AdminStationsState> loadStations({bool forceRefresh = false}) async {
    final cached = _cache;
    if (!forceRefresh && cached != null) return cached;
    final loaded = await guardInfra(_stations.readStations);
    _cache = loaded;
    return loaded;
  }

  @override
  Future<void> setStationStatus(
    String uid,
    StationApprovalStatus status,
  ) async {
    await guardInfra(() => _stations.writeStationStatus(uid, status));
    // A fila mudou de tamanho; obriga releitura em vez de remendar a lista.
    _cache = null;
  }

  @override
  Future<ReviewReportPage> loadReports({
    ReviewReportCursor? after,
    int limit = 20,
  }) => guardInfra(() => _reports.readReportPage(after: after, limit: limit));

  @override
  Future<void> dismissReport(ReviewReport report) => guardInfra(
    () => _reports.writeReportStatus(report, ReportStatus.dismissed),
  );

  @override
  Future<void> removeReportedReview(ReviewReport report) async {
    await guardInfra(() => _reports.deleteReportedReview(report));
    // A nota agregada do posto mudou.
    _cache = null;
  }
}
