// Aba "Avaliações": lista as avaliações do posto e permite denunciar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../station_details/domain/models/station_review.dart';
import '../../../station_details/presentation/widgets/station_details_error.dart';
import '../../../station_details/presentation/widgets/station_review_card.dart';
import '../providers/station_panel_providers.dart';
import '../providers/station_panel_reviews_providers.dart';
import '../widgets/report_reason_picker.dart';
import '../widgets/station_panel_placeholder_tab.dart';
import '../widgets/station_panel_section_header.dart';

class StationReviewsTab extends ConsumerWidget {
  const StationReviewsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(stationPanelViewModelProvider).valueOrNull?.uid;
    if (uid == null) return const SizedBox.shrink();

    final provider = stationPanelReviewsViewModelProvider(uid);
    final state = ref.watch(provider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => StationDetailsError(
        message: error.toString(),
        onRetry: () => ref.invalidate(provider),
      ),
      // Sem método de refresh na ViewModel: invalidar o provider reconstrói a
      // primeira página, que é o que o gesto deve fazer.
      data: (content) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          await ref.read(provider.future);
        },
        child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const StationPanelSectionHeader(
            title: 'Avaliações',
            subtitle: 'O que os clientes disseram sobre o posto.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (content.reviews.isEmpty)
            const StationPanelPlaceholderTab(
              icon: Icons.reviews_outlined,
              title: 'Sem avaliações ainda',
              message:
                  'As avaliações dos clientes aparecerão aqui quando '
                  'começarem a avaliar.',
            )
          else ...[
            for (final review in content.reviews)
              _ReviewWithReport(stationUid: uid, review: review),
            if (content.hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: OutlinedButton(
                    onPressed: content.isLoadingMore
                        ? null
                        : () => ref.read(provider.notifier).loadMore(),
                    child: content.isLoadingMore
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Carregar mais'),
                  ),
                ),
              ),
          ],
          ],
        ),
      ),
    );
  }
}

class _ReviewWithReport extends ConsumerWidget {
  const _ReviewWithReport({required this.stationUid, required this.review});

  final String stationUid;
  final StationReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        StationReviewCard(review: review),
        TextButton.icon(
          onPressed: () => _report(context, ref),
          icon: const Icon(Icons.flag_outlined, size: 16),
          label: const Text('Denunciar'),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final reason = await ReportReasonPicker.show(
      context,
      clientName: review.clientName,
    );
    if (reason == null) return;

    final notifier = ref.read(
      stationPanelReviewsViewModelProvider(stationUid).notifier,
    );
    final error = await notifier.reportReview(review, reason.wireValue);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Denúncia enviada para análise.')),
    );
  }
}
