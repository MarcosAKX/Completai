// Card com a avaliação do próprio motorista, não a média do posto.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/station_logo.dart';
import '../../../station_cover/presentation/providers/station_cover_providers.dart';
import '../../../station_details/presentation/widgets/average_star_rating.dart';
import '../../domain/models/my_review.dart';

class MyReviewCard extends ConsumerWidget {
  const MyReviewCard({required this.review, required this.onOpen, super.key});
  final MyReview review;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = review.station;
    final bytes = station == null
        ? null
        : ref.watch(stationCoverProvider(review.stationUid)).valueOrNull?.bytes;
    final date = review.createdAt;
    final dateLabel = date == null
        ? 'Data não informada'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Card(
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.primaryLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StationLogo(
                  stationName: station?.name ?? 'Posto',
                  imageBytes: bytes,
                  size: AppSpacing.xxl,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station?.name ?? 'Posto indisponível',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (station != null)
                        Text(
                          '${station.neighborhood} · ${station.city}',
                          style: AppTextStyles.caption,
                        ),
                      Text(
                        dateLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            const Text('Sua avaliação', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AverageStarRating(
                  value: review.rating.toDouble(),
                  size: AppSpacing.lg,
                ),
                Text(
                  '${review.rating},0',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              review.comment.isEmpty
                  ? 'Avaliação sem comentário.'
                  : review.comment,
              style: AppTextStyles.body,
            ),
            const Divider(height: AppSpacing.lg),
            TextButton(
              onPressed: station == null ? null : onOpen,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      station == null ? 'Posto não disponível' : 'Ver posto',
                    ),
                  ),
                  const Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
