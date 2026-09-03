// Indicador compacto e acessível das duas etapas de cadastro do posto.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppStepProgress extends StatelessWidget {
  const AppStepProgress({super.key, required this.current, this.total = 2});
  final int current;
  final int total;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Etapa $current de $total',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etapa $current de $total',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(total * 2 - 1, (index) {
            if (index.isEven) {
              final step = index ~/ 2 + 1;
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step <= current
                      ? AppColors.primary
                      : AppColors.surface,
                  border: Border.all(
                    color: step <= current
                        ? AppColors.primary
                        : AppColors.outline,
                  ),
                ),
              );
            }
            final segment = (index + 1) ~/ 2;
            return Expanded(
              child: Container(
                height: 3,
                color: segment < current
                    ? AppColors.primary
                    : AppColors.outline,
              ),
            );
          }),
        ),
      ],
    ),
  );
}
