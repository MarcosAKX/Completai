// Regressão do relato "coloquei aberto até as 22 e não vira aberto agora".
//
// Reproduz o caminho inteiro do painel: WeeklyHours (o que o dono edita) →
// toOpeningPeriods → stationHoursStatus (o mesmo cálculo da Home, do detalhe
// e dos favoritos), num domingo às 21:07.
//
// Domingo é o dia que mais esconde erro: é o último de `Weekday.values`, o
// primeiro de `DateTime.weekday` seria 7, e é o dia que as pessoas esquecem
// de preencher.
import 'package:completai/features/station_panel/domain/models/opening_hours.dart';
import 'package:completai/shared/models/station_hours_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 04/10/2026 é um domingo. 21:07 = antes das 22h.
  final domingoCedo = DateTime(2026, 10, 4, 21, 7);

  test('domingo 08:00-22:00 às 21:07 está aberto', () {
    final hours = const WeeklyHours.empty().withDay(
      Weekday.sunday,
      const DayHours(open: '08:00', close: '22:00'),
    );

    final status = stationHoursStatus(domingoCedo, hours.toOpeningPeriods());

    expect(status.isOpen, isTrue);
    expect(status.label, 'Aberto agora até 22:00');
  });

  test('domingo 08:00-22:00 às 22:30 está fechado', () {
    final hours = const WeeklyHours.empty().withDay(
      Weekday.sunday,
      const DayHours(open: '08:00', close: '22:00'),
    );

    final status = stationHoursStatus(
      DateTime(2026, 10, 4, 22, 30),
      hours.toOpeningPeriods(),
    );

    expect(status.isOpen, isFalse);
    expect(status.label, 'Fechado agora');
  });

  test('segunda a sábado preenchidos, domingo não: domingo fecha', () {
    // O caso que mais parece bug e não é: "copiar p/ todos" não foi usado e
    // o domingo ficou de fora.
    var hours = const WeeklyHours.empty();
    for (final day in Weekday.values.where((d) => d != Weekday.sunday)) {
      hours = hours.withDay(day, const DayHours(open: '08:00', close: '22:00'));
    }

    final status = stationHoursStatus(domingoCedo, hours.toOpeningPeriods());

    expect(status.isOpen, isFalse);
    expect(
      status.label,
      'Fechado hoje',
      reason: 'rótulo diferente de "Fechado agora": o dia nem foi configurado',
    );
  });

  test('filledWith cobre o domingo', () {
    final hours = const WeeklyHours.empty().filledWith(
      const DayHours(open: '08:00', close: '22:00'),
    );

    expect(
      stationHoursStatus(domingoCedo, hours.toOpeningPeriods()).isOpen,
      isTrue,
    );
  });

  test('todos os dias da semana respondem ao próprio horário', () {
    // 05/10/2026 é segunda; o laço cobre os sete dias em sequência.
    for (var i = 0; i < 7; i++) {
      final dia = DateTime(2026, 10, 5 + i, 15, 0);
      final weekday = Weekday.values[dia.weekday - 1];
      final hours = const WeeklyHours.empty().withDay(
        weekday,
        const DayHours(open: '08:00', close: '22:00'),
      );

      expect(
        stationHoursStatus(dia, hours.toOpeningPeriods()).isOpen,
        isTrue,
        reason: '${weekday.label} às 15:00 deveria estar aberto',
      );
    }
  });
}
