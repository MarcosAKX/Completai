// Garante o status correto para horários comuns e que atravessam meia-noite.
import 'package:completai/features/station_discovery/domain/models/station_summary.dart';
import 'package:completai/features/station_discovery/domain/station_opening_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const overnight = DailyHours(open: '18:00', close: '02:00');
  test('horário atravessando meia-noite abre nos dois lados', () {
    expect(isStationOpen(DateTime(2026, 1, 1, 23), overnight), isTrue);
    expect(isStationOpen(DateTime(2026, 1, 2, 1), overnight), isTrue);
    expect(isStationOpen(DateTime(2026, 1, 2, 12), overnight), isFalse);
  });
}
