// Conversão texto <-> preço de combustível.
import 'package:completai/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFuelPrice', () {
    test('campo vazio vira null', () {
      expect(parseFuelPrice(''), isNull);
      expect(parseFuelPrice('   '), isNull);
    });

    test('aceita vírgula, ponto de milhar e prefixo', () {
      expect(parseFuelPrice('5,499'), closeTo(5.499, 1e-9));
      expect(parseFuelPrice('R\$ 6,29'), closeTo(6.29, 1e-9));
      expect(parseFuelPrice('1.234,50'), closeTo(1234.50, 1e-9));
    });

    test('texto não numérico lança FormatException', () {
      expect(() => parseFuelPrice('abc'), throwsFormatException);
    });
  });

  group('formatFuelPrice', () {
    test('null vira string vazia', () => expect(formatFuelPrice(null), ''));

    test('remove zeros à direita e usa vírgula', () {
      expect(formatFuelPrice(5.5), '5,5');
      expect(formatFuelPrice(5.499), '5,499');
      expect(formatFuelPrice(6), '6');
    });

    test('ida e volta preserva o valor', () {
      for (final value in [3.999, 5.5, 6.29, 7.0]) {
        expect(parseFuelPrice(formatFuelPrice(value)), closeTo(value, 1e-9));
      }
    });
  });
}
