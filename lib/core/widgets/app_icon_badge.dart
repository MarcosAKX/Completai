// Badge reutilizável para destacar ícones nas telas de autenticação.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.circular = true,
    this.filled = true,
    this.size = AppSpacing.xxl,
  });
  final IconData icon;
  final bool circular;
  final bool filled;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: filled ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(
        circular ? AppSpacing.xl : AppSpacing.controlRadius,
      ),
    ),
    child: Icon(icon, color: AppColors.primary, size: size * .58),
  );
}
