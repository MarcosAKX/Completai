// Regra local do protótipo para intervalos comuns e que atravessam meia-noite.
class DailyOpeningHours {
  const DailyOpeningHours({required this.open, required this.close});

  final String open;
  final String close;
}

bool isWithinOpeningHours({
  required DateTime now,
  required DailyOpeningHours schedule,
}) {
  int minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  final current = now.hour * 60 + now.minute;
  final opening = minutes(schedule.open);
  final closing = minutes(schedule.close);
  if (opening == closing) return true;
  if (opening < closing) return current >= opening && current < closing;
  return current >= opening || current < closing;
}
