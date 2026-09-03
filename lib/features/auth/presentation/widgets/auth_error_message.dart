// Exibe a Failure do AsyncValue sem lançar ou consumir erros na View.
import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({super.key, required this.error});
  final Object? error;
  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    final message = error is Failure
        ? (error as Failure).message
        : 'Não foi possível concluir. Tente novamente.';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: AppTextStyles.caption.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
