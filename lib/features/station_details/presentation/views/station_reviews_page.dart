// Lista paginada de avaliações públicas com comentários completos.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/station_details_providers.dart';
import '../widgets/station_details_error.dart';
import '../widgets/station_review_card.dart';

class StationReviewsPage extends ConsumerWidget {
  const StationReviewsPage({required this.stationUid, super.key});

  final String stationUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = stationReviewsViewModelProvider(stationUid);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(title: const Text('Todas as avaliações')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => StationDetailsError(
          message: error.toString(),
          onRetry: () => ref.invalidate(provider),
        ),
        data: (content) => content.reviews.isEmpty
            ? const Center(child: Text('Este posto ainda não tem avaliações.'))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: content.reviews.length + (content.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < content.reviews.length) {
                    return StationReviewCard(review: content.reviews[index]);
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
    );
  }
}
