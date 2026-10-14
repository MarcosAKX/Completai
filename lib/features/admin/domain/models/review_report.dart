// Denúncia de avaliação, com o conteúdo denunciado junto.
//
// O documento vive em
// `public_stations/{stationUid}/reviews/{clientUid}/reports/{reporterUid}`.
// `stationUid` e `clientUid` vêm do CAMINHO, não de campos — por isso a
// consulta por `collectionGroup('reports')` não precisa de campo extra nem
// de índice adicional para saber de quem é a denúncia.
import '../../../station_details/domain/models/station_review.dart';
import '../../../../shared/models/report_reason.dart';
import 'report_status.dart';

class ReviewReport {
  const ReviewReport({
    required this.stationUid,
    required this.clientUid,
    required this.reporterUid,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.stationName = '',
    this.review,
    this.reviewMissing = false,
  });

  final String stationUid;
  final String clientUid;
  final String reporterUid;
  final ReportReason reason;
  final ReportStatus status;
  final DateTime? createdAt;

  /// Nome do posto, para o admin saber do que se trata sem abrir nada.
  final String stationName;

  /// A avaliação denunciada. `null` quando já foi removida.
  final StationReview? review;

  /// A avaliação não existe mais (removida por aqui ou pelo próprio autor).
  final bool reviewMissing;

  /// Identidade estável do documento, para `key` de lista e comparação.
  String get id => '$stationUid/$clientUid/$reporterUid';

  bool get isPending => status == ReportStatus.pending;

  /// Só faz sentido oferecer "remover avaliação" se ela ainda existe.
  bool get canRemoveReview => !reviewMissing && review != null;
}

class ReviewReportCursor {
  const ReviewReportCursor({
    required this.seconds,
    required this.nanoseconds,
    required this.documentPath,
  });

  final int seconds;
  final int nanoseconds;
  final String documentPath;
}

class ReviewReportPage {
  const ReviewReportPage({
    required this.reports,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<ReviewReport> reports;
  final ReviewReportCursor? nextCursor;
  final bool hasMore;
}
