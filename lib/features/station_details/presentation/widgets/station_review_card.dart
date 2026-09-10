// Card de avaliação reutilizado na prévia e na lista completa.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/station_review.dart';

class StationReviewCard extends StatelessWidget {
  const StationReviewCard({
    required this.review,
    this.preview = false,
    super.key,
  });

  final StationReview review;
  final bool preview;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: preview
          ? AppColors.stationPriceSurface
          : AppColors.screenBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                _initial(review.clientName),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _dateLabel(review.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${review.rating} ★',
              style: const TextStyle(
                color: Color(0xFFE6A700),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          review.comment.isEmpty ? 'Sem comentário.' : review.comment,
          maxLines: preview ? 3 : null,
          overflow: preview ? TextOverflow.ellipsis : TextOverflow.visible,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
}

// Usa a data original da avaliação no horário local do aparelho.
String _dateLabel(DateTime? value) {
  if (value == null) return 'Data não informada';
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
