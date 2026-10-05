// Denúncias de avaliação: manter ou remover a avaliação denunciada.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/review_report.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_report_card.dart';

class AdminReportsTab extends ConsumerStatefulWidget {
  const AdminReportsTab({super.key});

  @override
  ConsumerState<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends ConsumerState<AdminReportsTab> {
  String? _busyId;

  Future<void> _remove(ReviewReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover esta avaliação?'),
        content: const Text(
          'A avaliação sai do perfil do posto e a nota média é recalculada. '
          'Não há como desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _act(report, remove: true);
  }

  Future<void> _act(ReviewReport report, {required bool remove}) async {
    setState(() => _busyId = report.id);
    final notifier = ref.read(adminReportsViewModelProvider.notifier);
    final error = remove
        ? await notifier.removeReview(report)
        : await notifier.dismiss(report);
    if (!mounted) return;
    setState(() => _busyId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (remove
                  ? 'Avaliação removida e nota recalculada.'
                  : 'Denúncia descartada; a avaliação continua no ar.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsViewModelProvider);
    final notifier = ref.read(adminReportsViewModelProvider.notifier);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AdminErrorState(
        message: error.toString(),
        onRetry: notifier.refresh,
      ),
      data: (data) => RefreshIndicator(
        onRefresh: notifier.refresh,
        child: data.reports.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  AdminEmptyState(
                    icon: Icons.flag_outlined,
                    title: 'Nenhuma denúncia',
                    message:
                        'Quando um posto denunciar uma avaliação, ela aparece '
                        'aqui com o texto original para você decidir.',
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: data.reports.length + (data.hasMore ? 1 : 0),
                itemBuilder: (_, index) {
                  if (index == data.reports.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Center(
                        child: data.isLoadingMore
                            ? const CircularProgressIndicator()
                            : OutlinedButton(
                                onPressed: notifier.loadMore,
                                child: const Text('Carregar mais'),
                              ),
                      ),
                    );
                  }
                  final report = data.reports[index];
                  return AdminReportCard(
                    report: report,
                    busy: _busyId == report.id,
                    onDismiss: () => _act(report, remove: false),
                    onRemoveReview: () => _remove(report),
                  );
                },
              ),
      ),
    );
  }
}
