// Resumo do horário atual e semana expansível, incluindo virada da meia-noite.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/station_details.dart';
import 'station_details_section.dart';

class StationOpeningHoursSection extends StatefulWidget {
  const StationOpeningHoursSection({required this.hours, super.key});

  final Map<String, StationOpeningPeriod?> hours;

  @override
  State<StationOpeningHoursSection> createState() =>
      _StationOpeningHoursSectionState();
}

class _StationOpeningHoursSectionState
    extends State<StationOpeningHoursSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = stationHoursStatus(now, widget.hours);
    return StationDetailsSection(
      icon: Icons.schedule_rounded,
      title: 'Horário de funcionamento',
      trailing: IconButton(
        tooltip: _expanded ? 'Recolher horários' : 'Ver semana completa',
        onPressed: () => setState(() => _expanded = !_expanded),
        icon: Icon(
          _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: status.isOpen ? const Color(0xFF16A05D) : Colors.grey,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: status.isOpen
                        ? const Color(0xFF168A49)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < _keys.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        index == now.weekday - 1 ? 'Hoje' : _labels[index],
                        style: TextStyle(
                          color: index == now.weekday - 1
                              ? AppColors.primary
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(child: Text(_period(widget.hours[_keys[index]]))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

const _keys = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];
const _labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

({bool isOpen, String label}) stationHoursStatus(
  DateTime now,
  Map<String, StationOpeningPeriod?> hours,
) {
  final todayIndex = now.weekday - 1;
  final today = hours[_keys[todayIndex]];
  final previous = hours[_keys[(todayIndex + 6) % 7]];
  final current = now.hour * 60 + now.minute;

  int? minutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  if (previous != null) {
    final open = minutes(previous.open);
    final close = minutes(previous.close);
    if (open != null && close != null && open > close && current < close) {
      return (isOpen: true, label: 'Aberto agora até ${previous.close}');
    }
  }
  if (today == null) return (isOpen: false, label: 'Fechado hoje');
  final open = minutes(today.open);
  final close = minutes(today.close);
  if (open == null || close == null) {
    return (isOpen: false, label: 'Horário não informado');
  }
  final isOpen =
      open == close ||
      (open < close ? current >= open && current < close : current >= open);
  return (
    isOpen: isOpen,
    label: isOpen ? 'Aberto agora até ${today.close}' : 'Fechado agora',
  );
}

String _period(StationOpeningPeriod? value) =>
    value == null ? 'Fechado' : '${value.open} – ${value.close}';
