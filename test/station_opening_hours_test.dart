// Contrato semanal comum: Home, detalhe e favoritos usam o mesmo cálculo.
import 'package:completai/features/station_discovery/domain/station_opening_hours.dart';
import 'package:completai/shared/models/station_hours_status.dart';
import 'package:completai/shared/models/station_opening_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const overnight = StationOpeningPeriod(open: '18:00', close: '02:00');
  test(
    'expediente anterior segue aberto até fechar, mesmo com hoje fechado',
    () {
      const hours = {'monday': overnight, 'tuesday': null};
      expect(isStationOpen(DateTime(2026, 9, 7, 18), hours), isTrue);
      expect(isStationOpen(DateTime(2026, 9, 8, 0), hours), isTrue);
      expect(isStationOpen(DateTime(2026, 9, 8, 1, 59), hours), isTrue);
      expect(isStationOpen(DateTime(2026, 9, 8, 2), hours), isFalse);
      expect(
        stationHoursStatus(DateTime(2026, 9, 8, 1), hours).label,
        'Aberto agora até 02:00',
      );
    },
  );
  test('domingo para segunda também considera expediente anterior', () {
    expect(
      isStationOpen(DateTime(2026, 9, 7, 1), {'sunday': overnight}),
      isTrue,
    );
  });
  test('turno desta noite não abre antecipadamente na madrugada', () {
    expect(
      isStationOpen(DateTime(2026, 9, 8, 1), {'tuesday': overnight}),
      isFalse,
    );
    expect(
      isStationOpen(DateTime(2026, 9, 8, 18), {'tuesday': overnight}),
      isTrue,
    );
  });
  test('horário comum inclui abertura e exclui fechamento', () {
    const hours = {
      'tuesday': StationOpeningPeriod(open: '08:00', close: '18:00'),
    };
    expect(isStationOpen(DateTime(2026, 9, 8, 7, 59), hours), isFalse);
    expect(isStationOpen(DateTime(2026, 9, 8, 8), hours), isTrue);
    expect(isStationOpen(DateTime(2026, 9, 8, 18), hours), isFalse);
  });
  test(
    '24 horas vale para o dia configurado sem abrir dia seguinte fechado',
    () {
      const hours = {
        'monday': StationOpeningPeriod(open: '00:00', close: '00:00'),
      };
      expect(isStationOpen(DateTime(2026, 9, 7, 0), hours), isTrue);
      expect(isStationOpen(DateTime(2026, 9, 7, 23, 59), hours), isTrue);
      expect(
        stationHoursStatus(DateTime(2026, 9, 7, 12), hours).label,
        'Aberto 24 horas',
      );
      expect(isStationOpen(DateTime(2026, 9, 8, 0), hours), isFalse);
    },
  );
  test('horários ausentes ou inválidos não derrubam a listagem', () {
    final now = DateTime(2026, 9, 8, 12);
    expect(isStationOpen(now, {}), isFalse);
    for (final invalid in ['', 'abc', '25:00', '12:99', '-1:00']) {
      expect(
        isStationOpen(now, {
          'tuesday': StationOpeningPeriod(open: invalid, close: '18:00'),
        }),
        isFalse,
      );
    }
  });
}
