// Cabeçalho e resumo somente para leitura do perfil do motorista.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/contact_input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/client_profile.dart';
import 'client_profile_card.dart';

class ClientProfileSummary extends StatelessWidget {
  const ClientProfileSummary({
    required this.profile,
    required this.onEdit,
    super.key,
  });
  final ClientProfile profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final words = profile.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final initials = words
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: AppSpacing.xl,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initials.isEmpty ? 'M' : initials,
                style: AppTextStyles.title.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: AppTextStyles.title),
                  const Text(
                    'Motorista',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ClientProfileCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Meus dados', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.md),
                ClientProfileDataRow(
                  icon: Icons.person_outline,
                  label: 'Nome completo',
                  value: profile.name,
                ),
                const Divider(),
                ClientProfileDataRow(
                  icon: Icons.mail_outline,
                  label: 'E-mail',
                  value: profile.email,
                ),
                const Divider(),
                ClientProfileDataRow(
                  icon: Icons.phone_outlined,
                  label: 'Celular',
                  value: phoneMask(profile.phone.replaceAll(RegExp(r'\D'), '')),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: 'Editar meus dados', onPressed: onEdit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ClientProfileDataRow extends StatelessWidget {
  const ClientProfileDataRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label),
              Text(
                value.isEmpty ? 'Não informado' : value,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
