// Resumo agregado e até três avaliações públicas recentes.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/station_review.dart';
import 'average_star_rating.dart';
import 'station_details_section.dart';
import 'station_review_card.dart';

class StationReviewsPreview extends StatelessWidget {
  const StationReviewsPreview({
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
    required this.onReview,
    required this.onSeeAll,
    this.hasReviewed = false,
    this.currentClientUid,
    this.onReportReview,
    super.key,
  });

  final double averageRating;
  final int reviewCount;
  final List<StationReview> reviews;
  final VoidCallback onReview;
  final VoidCallback? onSeeAll;

  /// Já avaliou: o botão vira aviso. Avaliação é única e não se edita.
  final bool hasReviewed;

  /// Quem está vendo. Usado só para esconder "Denunciar" na própria
  /// avaliação; `null` quando não há sessão.
  final String? currentClientUid;

  /// Abre a denúncia da avaliação escolhida.
  final void Function(StationReview review)? onReportReview;

  @override
  Widget build(BuildContext context) => StationDetailsSection(
    icon: Icons.star_rounded,
    title: 'Avaliações',
    trailing: TextButton(onPressed: onSeeAll, child: const Text('Ver todas')),
    child: Column(
      children: [
        Row(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AverageStarRating(value: averageRating),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$reviewCount avaliações',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (reviews.isEmpty)
          const Text('Este posto ainda não recebeu avaliações.')
        else
          for (final review in reviews.take(3))
            StationReviewCard(
              review: review,
              preview: true,
              // Ninguém denuncia a própria avaliação: quem não quer mais a
              // dela apaga. As rules também recusam.
              onReport:
                  onReportReview == null ||
                      currentClientUid == null ||
                      currentClientUid == review.clientUid
                  ? null
                  : () => onReportReview!(review),
            ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: hasReviewed
              ? const _AlreadyReviewed()
              : OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('Avaliar posto'),
                ),
        ),
      ],
    ),
  );
}

/// Substitui o botão depois que o cliente avaliou. Não é um botão
/// desabilitado de propósito: desabilitado sugere "ainda não dá", e aqui
/// nunca mais vai dar.
class _AlreadyReviewed extends StatelessWidget {
  const _AlreadyReviewed();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.screenBackground,
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      border: Border.all(color: AppColors.outline),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'Você já avaliou este posto',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}
