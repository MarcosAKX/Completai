// Ação primária de rota, em largura total e sem expor telefone privado.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class StationDirectionsButton extends StatelessWidget {
  const StationDirectionsButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_rounded, size: AppSpacing.xl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Como chegar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onPressed == null
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Abrir no Google Maps',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onPressed == null
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.open_in_new_rounded, size: AppSpacing.md),
        ],
      ),
    ),
  );
}
