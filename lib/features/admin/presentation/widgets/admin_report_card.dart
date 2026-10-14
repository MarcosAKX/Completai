// Denúncia com o conteúdo denunciado junto, para o admin decidir sem sair
// da tela.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/review_report.dart';

class AdminReportCard extends StatelessWidget {
  const AdminReportCard({
    super.key,
    required this.report,
    required this.onDismiss,
    required this.onRemoveReview,
    this.busy = false,
  });

  final ReviewReport report;
  final VoidCallback onDismiss;
  final VoidCallback onRemoveReview;
  final bool busy;

  String _date(DateTime? value) => value == null
      ? 'Data não informada'
      : '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    final review = report.review;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  report.reason.label,
                  style: AppTextStyles.label,
                ),
              ),
              Text(
                _date(report.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            report.stationName.isEmpty
                ? 'Posto não identificado'
                : 'Denunciado por ${report.stationName}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // O conteúdo denunciado, textualmente. Sem ele o admin decidiria
          // no escuro.
          if (review != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.screenBackground,
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(review.clientName, style: AppTextStyles.label),
                      ),
                      Icon(Icons.star, size: 14, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Text('${review.rating}', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _date(review.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (review.comment.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(review.comment, style: AppTextStyles.body.copyWith(fontSize: 13)),
                  ],
                ],
              ),
            )
          else
            Text(
              'A avaliação já não existe mais.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          if (report.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onDismiss,
                    child: const Text('Manter'),
                  ),
                ),
                if (report.canRemoveReview) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onRemoveReview,
                      child: const Text('Remover'),
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                Icon(
                  report.status == ReportStatus.resolved
                      ? Icons.delete_outline
                      : Icons.check_circle_outline,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  report.status.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
