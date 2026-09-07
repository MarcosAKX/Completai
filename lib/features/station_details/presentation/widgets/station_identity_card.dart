// Identificação pública: marca, nota, funcionamento e distância.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/station_brand_badge.dart';
import '../../../../core/widgets/station_logo.dart';
import '../../domain/models/station_details.dart';

class StationIdentityCard extends StatelessWidget {
  const StationIdentityCard({
    required this.details,
    required this.isOpen,
    this.distanceKm,
    super.key,
  });

  final StationDetails details;
  final bool isOpen;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StationLogo(stationName: details.name, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StationBrandBadge(brand: details.brand),
                    const Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    Text(
                      '${details.averageRating.toStringAsFixed(1)} '
                      '(${details.reviewCount} avaliações)',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen ? const Color(0xFFE5F7EC) : AppColors.outline,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOpen ? 'Aberto agora' : 'Fechado',
                    style: TextStyle(
                      color: isOpen
                          ? const Color(0xFF168A49)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (distanceKm != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 19,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${details.neighborhood} · '
                          '${distanceKm!.toStringAsFixed(1)} km',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
