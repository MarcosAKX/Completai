// Calcula o funcionamento semanal sem depender de Flutter ou infraestrutura.
import 'station_opening_period.dart';

const stationWeekdayKeys = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

int? _minutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return hour * 60 + minute;
}

({bool isOpen, String label}) stationHoursStatus(
  DateTime now,
  Map<String, StationOpeningPeriod?> hours,
) {
  final todayIndex = now.weekday - 1;
  final today = hours[stationWeekdayKeys[todayIndex]];
  final previous = hours[stationWeekdayKeys[(todayIndex + 6) % 7]];
  final current = now.hour * 60 + now.minute;

  if (previous != null) {
    final open = _minutes(previous.open);
    final close = _minutes(previous.close);
    if (open != null && close != null && open > close && current < close) {
      return (isOpen: true, label: 'Aberto agora até ${previous.close}');
    }
  }
  if (today == null) return (isOpen: false, label: 'Fechado hoje');
  final open = _minutes(today.open);
  final close = _minutes(today.close);
  if (open == null || close == null) {
    return (isOpen: false, label: 'Horário não informado');
  }
  // No contrato atual, abertura igual ao fechamento representa dia 24 horas.
  if (open == close) return (isOpen: true, label: 'Aberto 24 horas');
  final isOpen = open < close
      ? current >= open && current < close
      : current >= open;
  return (
    isOpen: isOpen,
    label: isOpen ? 'Aberto agora até ${today.close}' : 'Fechado agora',
  );
}
