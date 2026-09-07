// Representa visualmente a média agregada das avaliações em cinco posições.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AverageStarRating extends StatelessWidget {
  const AverageStarRating({required this.value, this.size = 22, super.key});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 5.0).toDouble();
    final accessibleValue = normalized.toStringAsFixed(1).replaceAll('.', ',');

    return Semantics(
      label: 'Média $accessibleValue de 5 estrelas',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final position = index + 1;
            final icon = normalized >= position
                ? Icons.star_rounded
                : normalized >= position - 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;

            return Icon(icon, color: AppColors.accent, size: size);
          }),
        ),
      ),
    );
  }
}
