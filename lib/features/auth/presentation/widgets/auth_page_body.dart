// Estrutura responsiva compartilhada: todo formulário permanece rolável.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon_badge.dart';

class AuthPageBody extends StatelessWidget {
  const AuthPageBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.icon,
    this.header,
    this.card = false,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  final IconData? icon;
  final Widget? header;
  final bool card;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                header!,
                const SizedBox(height: AppSpacing.lg),
              ],
              if (!card && icon != null) ...[
                Align(
                  alignment: Alignment.center,
                  child: AppIconBadge(icon: icon!, filled: false, size: 58),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (!card) ...[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (card)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (icon != null) ...[
                        Align(
                          child: AppIconBadge(
                            icon: icon!,
                            filled: false,
                            size: 58,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...children,
                    ],
                  ),
                )
              else
                ...children,
            ],
          ),
        ),
      ),
    ),
  );
}
