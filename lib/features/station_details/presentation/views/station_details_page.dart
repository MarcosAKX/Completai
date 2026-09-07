// Perfil público completo aberto a partir de um card da home do motorista.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../station_cover/presentation/providers/station_cover_providers.dart';
import '../providers/station_details_providers.dart';
import '../viewmodels/station_details_viewmodel.dart';
import '../widgets/station_details_error.dart';
import '../widgets/station_details_header.dart';
import '../widgets/station_directions_button.dart';
import '../widgets/station_fuel_prices_section.dart';
import '../widgets/station_identity_card.dart';
import '../widgets/station_opening_hours_section.dart';
import '../widgets/station_review_sheet.dart';
import '../widgets/station_reviews_preview.dart';
import '../widgets/station_services_section.dart';
import 'station_reviews_page.dart';

class StationDetailsPage extends ConsumerWidget {
  const StationDetailsPage({
    required this.stationUid,
    this.distanceKm,
    super.key,
  });

  final String stationUid;
  final double? distanceKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = stationDetailsViewModelProvider(stationUid);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Detalhes do posto'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            tooltip: state.valueOrNull?.isFavorite == true
                ? 'Remover dos favoritos'
                : 'Adicionar aos favoritos',
            onPressed: state.valueOrNull == null
                ? null
                : () => _toggleFavorite(context, viewModel),
            icon: Icon(
              state.valueOrNull?.isFavorite == true
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => StationDetailsError(
          message: error.toString(),
          onRetry: viewModel.refresh,
        ),
        data: (content) {
          final cover = ref.watch(stationCoverProvider(stationUid));
          final status = stationHoursStatus(
            DateTime.now(),
            content.details.openingHours,
          );
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: StationDetailsHeader(
                    imageBytes: cover.valueOrNull?.bytes,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      StationIdentityCard(
                        details: content.details,
                        isOpen: status.isOpen,
                        distanceKm: distanceKm,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StationDirectionsButton(
                        onPressed: () => _openDirections(context, viewModel),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StationFuelPricesSection(details: content.details),
                      const SizedBox(height: AppSpacing.md),
                      StationServicesSection(
                        services: content.details.services,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StationOpeningHoursSection(
                        hours: content.details.openingHours,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StationReviewsPreview(
                        averageRating: content.details.averageRating,
                        reviewCount: content.details.reviewCount,
                        reviews: content.reviews,
                        onSeeAll: content.details.reviewCount == 0
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => StationReviewsPage(
                                    stationUid: stationUid,
                                  ),
                                ),
                              ),
                        onReview: () => _review(context, viewModel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    StationDetailsViewModel viewModel,
  ) async {
    final ok = await viewModel.toggleFavorite();
    if (!context.mounted || ok) return;
    _showError(context);
  }

  Future<void> _openDirections(
    BuildContext context,
    StationDetailsViewModel viewModel,
  ) async {
    final ok = await viewModel.openDirections();
    if (!context.mounted || ok) return;
    _showError(context);
  }

  Future<void> _review(
    BuildContext context,
    StationDetailsViewModel viewModel,
  ) async {
    final draft = await showModalBottomSheet<StationReviewDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const StationReviewSheet(),
    );
    if (draft == null) return;
    final ok = await viewModel.submitReview(
      rating: draft.rating,
      comment: draft.comment,
    );
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avaliação publicada.')));
    } else {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível concluir a operação.')),
    );
  }
}
