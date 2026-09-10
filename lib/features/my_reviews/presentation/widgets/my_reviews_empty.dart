// Estado vazio e busca sem correspondências, com retorno à descoberta.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class MyReviewsEmpty extends StatelessWidget {
  const MyReviewsEmpty({
    required this.searching,
    required this.hasMore,
    required this.onExplore,
    super.key,
  });
  final bool searching;
  final bool hasMore;
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
    child: Column(
      children: [
        const Icon(
          Icons.rate_review_outlined,
          size: AppSpacing.xxl,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          searching
              ? 'Nenhuma avaliação encontrada'
              : hasMore
              ? 'Nenhuma avaliação de posto nesta página'
              : 'Você ainda não avaliou nenhum posto',
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!searching && !hasMore)
          AppButton(label: 'Explorar postos', onPressed: onExplore),
      ],
    ),
  );
}
