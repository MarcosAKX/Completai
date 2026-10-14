// Estado da aba de denúncias: página acumulada e cursor da próxima.
import 'review_report.dart';

class AdminReportsState {
  const AdminReportsState({
    required this.reports,
    required this.cursor,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  const AdminReportsState.empty()
    : reports = const [],
      cursor = null,
      hasMore = false,
      isLoadingMore = false;

  final List<ReviewReport> reports;
  final ReviewReportCursor? cursor;
  final bool hasMore;
  final bool isLoadingMore;

  int get pendingCount => reports.where((report) => report.isPending).length;

  AdminReportsState copyWith({
    List<ReviewReport>? reports,
    ReviewReportCursor? cursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) => AdminReportsState(
    reports: reports ?? this.reports,
    cursor: cursor ?? this.cursor,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}
