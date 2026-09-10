// Estado vazio distingue ausência de favoritos de busca sem resultados.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class FavoritesEmpty extends StatelessWidget {
  const FavoritesEmpty({
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
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Column(
      children: [
        const Icon(
          Icons.favorite_border,
          size: AppSpacing.xxl,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          searching
              ? 'Nenhum resultado nos favoritos carregados'
              : hasMore
              ? 'Nenhum posto disponível nesta página'
              : 'Você ainda não salvou nenhum posto',
          textAlign: TextAlign.center,
          style: AppTextStyles.title,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!searching && !hasMore)
          AppButton(label: 'Explorar postos', onPressed: onExplore),
      ],
    ),
  );
}
