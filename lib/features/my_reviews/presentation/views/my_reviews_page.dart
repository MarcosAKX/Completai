// Histórico pessoal navegável; dados e paginação são controlados pelo ViewModel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../station_details/presentation/views/station_details_page.dart';
import '../providers/my_reviews_providers.dart';
import '../widgets/my_review_card.dart';
import '../widgets/my_reviews_empty.dart';

class MyReviewsPage extends ConsumerWidget {
  const MyReviewsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(sessionViewModelProvider).valueOrNull?.uid;
    final provider = uid == null ? null : myReviewsViewModelProvider(uid);
    final state = provider == null ? null : ref.watch(provider);
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Minhas avaliações'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
      ),
      body: state == null
          ? const Center(
              child: Text('Entre na conta para consultar suas avaliações.'),
            )
          : state.when(
              skipError: state.hasValue,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error.toString()),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Tentar novamente',
                        onPressed: () => ref.invalidate(provider!),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                final vm = ref.read(provider!.notifier);
                final visible = data.visible;
                return RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: visible.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Os postos que você avaliou.',
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              initialValue: data.search,
                              onChanged: vm.search,
                              enabled: !state.isLoading,
                              decoration: const InputDecoration(
                                hintText: 'Buscar posto ou bairro',
                                prefixIcon: Icon(Icons.search),
                                filled: true,
                                fillColor: AppColors.surface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: AppSpacing.sm,
                              children: [
                                Text(
                                  '${data.reviews.length} avaliações${data.hasMore ? ' carregadas' : ''}',
                                  style: AppTextStyles.label,
                                ),
                                const Text(
                                  'Mais recentes',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                            if (data.hasMore)
                              const Text(
                                'Busca nas avaliações carregadas.',
                                style: AppTextStyles.caption,
                              ),
                            if (state.isLoading)
                              const LinearProgressIndicator(),
                            if (state.hasError)
                              Text(
                                state.error.toString(),
                                style: const TextStyle(color: AppColors.error),
                              ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        );
                      }
                      if (index <= visible.length) {
                        final review = visible[index - 1];
                        return MyReviewCard(
                          key: ValueKey(review.stationUid),
                          review: review,
                          onOpen: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => StationDetailsPage(
                                  stationUid: review.stationUid,
                                ),
                              ),
                            );
                            if (context.mounted) await vm.refresh();
                          },
                        );
                      }
                      return Column(
                        children: [
                          if (visible.isEmpty)
                            MyReviewsEmpty(
                              searching: data.search.isNotEmpty,
                              hasMore: data.hasMore,
                              onExplore: () => Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              ),
                            ),
                          if (data.hasMore)
                            AppButton(
                              label: 'Carregar mais',
                              isLoading: state.isLoading,
                              onPressed: vm.loadMore,
                            ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Text(
                              'Este histórico reúne suas avaliações de postos.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
