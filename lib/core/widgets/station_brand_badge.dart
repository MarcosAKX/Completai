// Selo da bandeira do posto — pílula escura com ícone, como nas referências.
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../shared/models/station_brand.dart';

/// Cor de acento de cada bandeira. São cores de marca (fora da paleta do
/// design system de propósito — identidade visual do posto).
Color brandAccent(StationBrand brand) => switch (brand) {
  StationBrand.shell => const Color(0xFFED1C24),
  StationBrand.ipiranga => const Color(0xFF00539F),
  StationBrand.petrobras => const Color(0xFF00A335),
  StationBrand.ale => const Color(0xFFE30613),
  StationBrand.raizen => const Color(0xFF0A7C3E),
  StationBrand.branca => AppColors.textSecondary,
  StationBrand.outra => AppColors.textSecondary,
};

class StationBrandBadge extends StatelessWidget {
  const StationBrandBadge({super.key, required this.brand});

  final StationBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.onSurface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_gas_station, size: 14, color: brandAccent(brand)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            brand.label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}
