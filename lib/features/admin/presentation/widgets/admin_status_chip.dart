// Selo de situação, reaproveitado pelas abas de postos.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/station_approval_status.dart';

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status});

  final StationApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      StationApprovalStatus.approved => (
        AppColors.successSurface,
        AppColors.success,
        Icons.check_circle_outline,
      ),
      StationApprovalStatus.pending => (
        AppColors.primaryLight,
        AppColors.primary,
        Icons.schedule,
      ),
      StationApprovalStatus.rejected => (
        AppColors.outline,
        AppColors.textSecondary,
        Icons.block,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: AppTextStyles.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
