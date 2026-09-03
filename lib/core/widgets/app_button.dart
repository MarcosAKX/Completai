// Botão base acessível, com estado ocupado e tokens do tema.
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: isLoading,
    child: FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) ...[
            SizedBox.square(
              dimension: AppSpacing.progressSize,
              child: CircularProgressIndicator(
                strokeWidth: AppSpacing.progressStroke,
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: 'Carregando',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}
