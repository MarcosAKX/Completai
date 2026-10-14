// Posto na visão do admin: dados de conferência e ações de aprovação.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/station_brand_badge.dart';
import '../../domain/models/admin_station.dart';
import 'admin_status_chip.dart';

class AdminStationCard extends StatelessWidget {
  const AdminStationCard({
    super.key,
    required this.station,
    this.onApprove,
    this.onReject,
    this.busy = false,
  });

  final AdminStation station;

  /// Ausentes na aba de listados, que é só leitura.
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      border: Border.all(color: AppColors.outline),
      boxShadow: [
        BoxShadow(
          color: AppColors.onSurface.withValues(alpha: .06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                station.name.isEmpty ? 'Posto sem nome' : station.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title.copyWith(fontSize: 17),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StationBrandBadge(brand: station.brand),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AdminStatusChip(status: station.status),
        const SizedBox(height: AppSpacing.md),
        _Field(icon: Icons.location_on_outlined, label: 'Endereço', value: station.location),
        _Field(icon: Icons.markunread_mailbox_outlined, label: 'CEP', value: station.cepFormatted),
        _Field(icon: Icons.badge_outlined, label: 'CNPJ', value: station.cnpjFormatted),
        _Field(icon: Icons.mail_outline, label: 'E-mail', value: station.email),
        _Field(icon: Icons.phone_outlined, label: 'Telefone', value: station.phone),
        if (station.privateDataMissing) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Dados privados indisponíveis — conferir antes de aprovar.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
        if (onApprove != null || onReject != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (onReject != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Recusar'),
                  ),
                ),
              if (onReject != null && onApprove != null)
                const SizedBox(width: AppSpacing.sm),
              if (onApprove != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprovar'),
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '—' : value,
            style: AppTextStyles.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
