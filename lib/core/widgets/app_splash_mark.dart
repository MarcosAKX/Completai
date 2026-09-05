// Marca animada exibida durante o carregamento inicial (splash).
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_splash_hose_painter.dart';

class AppSplashMark extends StatefulWidget {
  const AppSplashMark({super.key});

  @override
  State<AppSplashMark> createState() => _AppSplashMarkState();
}

class _AppSplashMarkState extends State<AppSplashMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SplashHoseAnimation(progress: _controller.value),
        Text(
          'Completai!',
          style: AppTextStyles.title.copyWith(
            color: AppColors.onPrimary,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Preparando seu próximo abastecimento',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onPrimary.withValues(alpha: .72),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _LoadingDots(progress: _controller.value),
      ],
    ),
  );
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(3, (index) {
      final phase = (progress * 3 - index * .25) % 1;
      final opacity = .25 + .75 * (1 - (2 * phase - 1).abs());
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Opacity(
          opacity: opacity.clamp(.25, 1),
          child: const CircleAvatar(
            radius: 3,
            backgroundColor: AppColors.onPrimary,
          ),
        ),
      );
    }),
  );
}
