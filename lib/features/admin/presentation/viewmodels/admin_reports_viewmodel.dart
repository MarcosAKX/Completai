// Denúncias de avaliação: página de 20, descartar e remover avaliação.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/models/admin_reports_state.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/review_report.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminReportsViewModel extends AsyncNotifier<AdminReportsState> {
  AdminReportsViewModel(this._repositoryProvider);

  final ProviderListenable<AdminRepository> _repositoryProvider;

  AdminRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<AdminReportsState> build() => _firstPage();

  Future<AdminReportsState> _firstPage() async {
    final page = await _repository.loadReports();
    return AdminReportsState(
      reports: page.reports,
      cursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<AdminReportsState>().copyWithPrevious(state);
    state = await AsyncValue.guard(_firstPage);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    final cursor = current.cursor;
    if (cursor == null) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.loadReports(after: cursor);
      state = AsyncData(
        current.copyWith(
          reports: [...current.reports, ...page.reports],
          cursor: page.nextCursor,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } on Failure {
      // Mantém o que já estava na tela; o usuário pode tentar de novo.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Descarta a denúncia, mantendo a avaliação no ar.
  Future<String?> dismiss(ReviewReport report) => _act(
    report,
    () => _repository.dismissReport(report),
    ReportStatus.dismissed,
  );

  /// Remove a avaliação denunciada e marca a denúncia como resolvida.
  Future<String?> removeReview(ReviewReport report) => _act(
    report,
    () => _repository.removeReportedReview(report),
    ReportStatus.resolved,
  );

  /// Atualiza só o item afetado, em vez de recarregar a lista: recarregar
  /// perderia as páginas já abertas e devolveria o admin ao topo.
  Future<String?> _act(
    ReviewReport report,
    Future<void> Function() write,
    ReportStatus resulting,
  ) async {
    final current = state.valueOrNull;
    if (current == null) return 'Nada carregado ainda.';
    try {
      await write();
      state = AsyncData(
        current.copyWith(
          reports: [
            for (final item in current.reports)
              if (item.id == report.id)
                ReviewReport(
                  stationUid: item.stationUid,
                  clientUid: item.clientUid,
                  reporterUid: item.reporterUid,
                  reason: item.reason,
                  status: resulting,
                  createdAt: item.createdAt,
                  stationName: item.stationName,
                  review: resulting == ReportStatus.resolved
                      ? null
                      : item.review,
                  reviewMissing: resulting == ReportStatus.resolved
                      ? true
                      : item.reviewMissing,
                )
              else
                item,
          ],
        ),
      );
      return null;
    } on Failure catch (error) {
      return error.message;
    } on AppException catch (error) {
      return error.message;
    }
  }
}
