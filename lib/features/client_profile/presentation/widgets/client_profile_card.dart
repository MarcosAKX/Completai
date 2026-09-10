// Superfície do perfil alinhada aos cards brancos e arredondados da home.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ClientProfileCard extends StatelessWidget {
  const ClientProfileCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surface,
    surfaceTintColor: AppColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      side: const BorderSide(color: AppColors.primaryLight),
    ),
    child: child,
  );
}
