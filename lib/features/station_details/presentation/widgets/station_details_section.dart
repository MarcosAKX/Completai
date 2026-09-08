// Superfície e título compartilhados pelas seções do perfil público.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class StationDetailsSection extends StatelessWidget {
  const StationDetailsSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 3,
    shadowColor: AppColors.primary.withValues(alpha: 0.16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.stationCardBorder),
    ),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    ),
  );
}
