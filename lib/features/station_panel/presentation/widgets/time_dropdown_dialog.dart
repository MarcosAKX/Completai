// Escolha de horário por listas suspensas: hora e minuto, sem digitar.
//
// Substitui o `showTimePicker` do Material, que abre num mostrador analógico
// confuso para um horário comercial redondo, e cuja alternativa é teclado.
// Aqui são dois toques e pronto.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class TimeDropdownDialog extends StatefulWidget {
  const TimeDropdownDialog({
    super.key,
    required this.title,
    required this.initial,
  });

  final String title;
  final TimeOfDay initial;

  /// Abre e devolve o horário escolhido, ou `null` se cancelou.
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required String title,
    required TimeOfDay initial,
  }) => showDialog<TimeOfDay>(
    context: context,
    builder: (_) => TimeDropdownDialog(title: title, initial: initial),
  );

  /// Minutos oferecidos. O valor atual entra na lista mesmo fora da grade,
  /// senão um horário já gravado como 01:59 sumiria ao abrir o seletor.
  static List<int> minuteOptions(int current) =>
      ({0, 15, 30, 45, current}.toList()..sort());

  @override
  State<TimeDropdownDialog> createState() => _TimeDropdownDialogState();
}

class _TimeDropdownDialogState extends State<TimeDropdownDialog> {
  late int _hour = widget.initial.hour;
  late int _minute = widget.initial.minute;

  String get _preview =>
      '${_hour.toString().padLeft(2, '0')}:'
      '${_minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title, style: AppTextStyles.title.copyWith(fontSize: 18)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'Hora',
                value: _hour,
                options: List.generate(24, (i) => i),
                onChanged: (value) => setState(() => _hour = value),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(':', style: TextStyle(fontSize: 22)),
            ),
            Expanded(
              child: _Field(
                label: 'Minuto',
                value: _minute,
                options: TimeDropdownDialog.minuteOptions(widget.initial.minute),
                onChanged: (value) => setState(() => _minute = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Confirmação visível do que vai ser gravado, no mesmo formato que
        // aparece no card.
        Text(
          _preview,
          style: AppTextStyles.title.copyWith(
            fontSize: 26,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute)),
        child: const Text('OK'),
      ),
    ],
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: AppSpacing.xs),
      DropdownButtonFormField<int>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(
                option.toString().padLeft(2, '0'),
                style: AppTextStyles.body,
              ),
            ),
        ],
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    ],
  );
}
