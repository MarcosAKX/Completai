// Conversão texto <-> preço de combustível (R$ x,xxx por litro), sem dependência externa.
import 'package:flutter/services.dart';

/// Faixa aceita para preço de combustível por litro. Fora disso é digitação
/// claramente equivocada e o formulário rejeita.
const double kMinFuelPrice = 0.01;
const double kMaxFuelPrice = 99.999;

/// Converte o texto digitado (`"5,499"`, `"R$ 5.49"`, `""`) em um valor.
///
/// Retorna `null` quando o campo está vazio (preço não informado) e lança
/// [FormatException] quando há texto mas ele não representa um número válido.
double? parseFuelPrice(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final normalized = trimmed
      .replaceAll(RegExp(r'[R$\s]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) throw FormatException('Preço inválido', raw);
  return value;
}

/// Formata o valor guardado para exibição no campo (`5.499` -> `"5,499"`).
String formatFuelPrice(double? value) {
  if (value == null) return '';
  return value
      .toStringAsFixed(3)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'[.,]$'), '')
      .replaceAll('.', ',');
}

/// Mantém o campo de preço em `dígitos + uma vírgula + até 3 casas`.
class FuelPriceInputFormatter extends TextInputFormatter {
  const FuelPriceInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('.', ',');
    final match = RegExp(r'^\d{0,2}(,\d{0,3})?').firstMatch(text);
    final formatted = match?.group(0) ?? '';
    if (formatted == newValue.text) return newValue;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
