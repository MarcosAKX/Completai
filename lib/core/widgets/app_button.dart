// Botão base acessível, com estado ocupado e tokens do tema.
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox.square(
            dimension: AppSpacing.progressSize,
            child: CircularProgressIndicator(
              strokeWidth: AppSpacing.progressStroke,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    return Semantics(
      liveRegion: isLoading,
      child: SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                child: child,
              )
            : FilledButton(
                onPressed: isLoading ? null : onPressed,
                child: child,
              ),
      ),
    );
  }
}
