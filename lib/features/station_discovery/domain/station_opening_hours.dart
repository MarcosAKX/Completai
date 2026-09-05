// Calcula o status atual, incluindo horários que atravessam meia-noite.
import 'models/station_summary.dart';

bool isStationOpen(DateTime now, DailyHours? hours) {
  if (hours == null) return false;
  int minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  final current = now.hour * 60 + now.minute;
  final opening = minutes(hours.open);
  final closing = minutes(hours.close);
  if (opening == closing) return true;
  if (opening < closing) return current >= opening && current < closing;
  return current >= opening || current < closing;
}
