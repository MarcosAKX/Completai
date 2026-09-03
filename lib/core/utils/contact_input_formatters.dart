// Máscaras simples sem dependência externa para telefone e CNPJ brasileiros.
import 'package:flutter/services.dart';

final phoneInputFormatter = _DigitMaskFormatter(phoneMask);
final cnpjInputFormatter = _DigitMaskFormatter(cnpjMask);

String phoneMask(String digits) {
  final value = digits.substring(0, digits.length.clamp(0, 11));
  if (value.length <= 2) return value.isEmpty ? '' : '($value';
  final area = value.substring(0, 2);
  final number = value.substring(2);
  final split = number.length > 8 ? 5 : 4;
  if (number.length <= split) return '($area) $number';
  return '($area) ${number.substring(0, split)}-${number.substring(split)}';
}

String cnpjMask(String digits) {
  final value = digits.substring(0, digits.length.clamp(0, 14));
  final buffer = StringBuffer();
  for (var index = 0; index < value.length; index++) {
    if (index == 2 || index == 5) buffer.write('.');
    if (index == 8) buffer.write('/');
    if (index == 12) buffer.write('-');
    buffer.write(value[index]);
  }
  return buffer.toString();
}

class _DigitMaskFormatter extends TextInputFormatter {
  _DigitMaskFormatter(this.mask);
  final String Function(String) mask;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = mask(newValue.text.replaceAll(RegExp(r'\D'), ''));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
