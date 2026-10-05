// Escolha do motivo da denúncia: lista fechada, sem campo de texto.
//
// Os valores enviados são os `wireValue` de `ReportReason`, e as
// `firestore.rules` recusam qualquer outro — digitar motivo livre deixaria
// a denúncia ilegível para o admin e abriria espaço para abuso no campo.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/report_reason.dart';

class ReportReasonPicker extends StatelessWidget {
  const ReportReasonPicker({super.key, required this.clientName});

  final String clientName;

  /// Abre a folha e devolve o motivo escolhido, ou `null` se cancelou.
  static Future<ReportReason?> show(
    BuildContext context, {
    required String clientName,
  }) => showModalBottomSheet<ReportReason>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ReportReasonPicker(clientName: clientName),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Denunciar avaliação', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'De $clientName. Escolha o motivo; um administrador vai analisar.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final reason in ReportReason.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(
                      reason.label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      reason.description,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pop(reason),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
