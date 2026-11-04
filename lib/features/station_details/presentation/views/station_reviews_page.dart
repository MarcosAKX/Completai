// Lista paginada de avaliações públicas com comentários completos.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/report_reason_picker.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/station_review.dart';
import '../providers/station_details_providers.dart';
import '../widgets/station_details_error.dart';
import '../viewmodels/station_reviews_viewmodel.dart';
import '../widgets/station_review_card.dart';

class StationReviewsPage extends ConsumerWidget {
  const StationReviewsPage({required this.stationUid, super.key});

  final String stationUid;

  /// Mesma denúncia da prévia. A lista não muda: a avaliação só sai se o
  /// admin aprovar.
  Future<void> _report(
    BuildContext context,
    StationReviewsViewModel viewModel,
    StationReview review,
  ) async {
    final reason = await ReportReasonPicker.show(
      context,
      clientName: review.clientName,
    );
    if (reason == null || !context.mounted) return;
    final error = await viewModel.reportReview(review, reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Denúncia enviada para análise.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = stationReviewsViewModelProvider(stationUid);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    final uid = ref.watch(sessionViewModelProvider).valueOrNull?.uid;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(title: const Text('Todas as avaliações')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => StationDetailsError(
          message: error.toString(),
          onRetry: () => ref.invalidate(provider),
        ),
        data: (content) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(provider);
            await ref.read(provider.future);
          },
          // Lista vazia também precisa rolar, senão o gesto não dispara.
          child: content.reviews.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('Este posto ainda não tem avaliações.')),
                  ],
                )
              : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: content.reviews.length + (content.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < content.reviews.length) {
                    final review = content.reviews[index];
                    return StationReviewCard(
                      review: review,
                      // Própria avaliação não tem "Denunciar": quem não quer
                      // mais a dela apaga. As rules também recusam.
                      onReport: uid == null || uid == review.clientUid
                          ? null
                          : () => _report(context, viewModel, review),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: OutlinedButton(
                      onPressed: content.isLoadingMore
                          ? null
                          : viewModel.loadMore,
                      child: content.isLoadingMore
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Carregar mais'),
                    ),
                  );
                },
                ),
        ),
      ),
    );
  }
}
