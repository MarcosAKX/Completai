// Modelo de horário semanal: serialização, edição e igualdade.
import 'package:completai/features/station_panel/domain/models/opening_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromWire ignora dias nulos e malformados', () {
    final hours = WeeklyHours.fromWire({
      'monday': {'open': '08:00', 'close': '18:00'},
      'tuesday': null,
      'wednesday': {'open': '', 'close': '18:00'},
      'thursday': 'lixo',
    });
    expect(hours.isOpen(Weekday.monday), isTrue);
    expect(hours.forDay(Weekday.monday)!.close, '18:00');
    expect(hours.isOpen(Weekday.tuesday), isFalse);
    expect(hours.isOpen(Weekday.wednesday), isFalse);
    expect(hours.isOpen(Weekday.thursday), isFalse);
  });

  test('toWire tem sempre as 7 chaves, null para dia fechado', () {
    final wire = const WeeklyHours.empty()
        .withDay(Weekday.friday, const DayHours(open: '06:00', close: '22:00'))
        .toWire();
    expect(wire.keys, containsAll(Weekday.values.map((d) => d.wireKey)));
    expect(wire['friday'], {'open': '06:00', 'close': '22:00'});
    expect(wire['monday'], isNull);
  });

  test('ida e volta preserva os dias', () {
    final original = const WeeklyHours.empty()
        .withDay(Weekday.monday, const DayHours(open: '08:00', close: '12:00'))
        .withDay(Weekday.sunday, const DayHours(open: '09:00', close: '13:00'));
    expect(WeeklyHours.fromWire(original.toWire()), original);
  });

  test('withDay(null) fecha o dia', () {
    final hours = const WeeklyHours.empty()
        .withDay(Weekday.monday, const DayHours(open: '08:00', close: '18:00'))
        .withDay(Weekday.monday, null);
    expect(hours.anyInformed, isFalse);
  });

  test('filledWith aplica o mesmo horário a todos os dias', () {
    final hours = const WeeklyHours.empty()
        .filledWith(const DayHours(open: '07:00', close: '19:00'));
    expect(Weekday.values.every(hours.isOpen), isTrue);
    expect(hours.forDay(Weekday.sunday)!.open, '07:00');
  });
}
