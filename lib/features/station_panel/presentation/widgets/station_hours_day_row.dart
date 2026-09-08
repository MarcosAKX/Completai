// Uma linha de horário: dia da semana + aberto/fechado + abre/fecha.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/opening_hours.dart';

class StationHoursDayRow extends StatelessWidget {
  const StationHoursDayRow({
    super.key,
    required this.day,
    required this.hours,
    required this.onChanged,
  });

  final Weekday day;

  /// `null` = fechado nesse dia.
  final DayHours? hours;

  final ValueChanged<DayHours?> onChanged;

  static const _defaultHours = DayHours(open: '08:00', close: '18:00');

  Future<void> _pick(BuildContext context, {required bool isOpen}) async {
    final current = _parse(isOpen ? hours!.open : hours!.close);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final value = _format(picked);
    onChanged(
      isOpen
          ? hours!.copyWith(open: value)
          : hours!.copyWith(close: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = hours != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(day.label, style: AppTextStyles.label),
          ),
          Switch(
            value: open,
            onChanged: (on) => onChanged(on ? _defaultHours : null),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (open)
            Expanded(
              child: Row(
                children: [
                  _TimeChip(
                    label: hours!.open,
                    onTap: () => _pick(context, isOpen: true),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text('às'),
                  ),
                  _TimeChip(
                    label: hours!.close,
                    onTap: () => _pick(context, isOpen: false),
                  ),
                ],
              ),
            )
          else
            Text(
              'Fechado',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSpacing.sm),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: AppColors.primary),
      ),
    ),
  );
}

TimeOfDay _parse(String value) {
  final parts = value.split(':');
  final h = int.tryParse(parts.first) ?? 8;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
}

String _format(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
