// Campo exibido sem edição: valor definido pelo sistema (CNPJ, cidade do MVP).
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppReadOnlyField extends StatelessWidget {
  const AppReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.helperText,
  });

  final String label;
  final String value;
  final IconData? icon;

  /// Explica por que o campo não é editável.
  final String? helperText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: AppSpacing.sm),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.screenBackground,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.lock_outline, size: 16, color: AppColors.outline),
          ],
        ),
      ),
      if (helperText != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          helperText!,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ],
  );
}
