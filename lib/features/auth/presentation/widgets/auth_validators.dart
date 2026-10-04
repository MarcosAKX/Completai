// Validações locais de formulário; a ViewModel continua responsável pelas operações.
String? requiredField(String? value) =>
    value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
String? emailField(String? value) {
  if (requiredField(value) != null) return 'Informe seu e-mail';
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
      ? null
      : 'E-mail inválido';
}

String? passwordField(String? value) {
  if (value == null || value.length < 6) return 'Use pelo menos 6 caracteres';
  return null;
}

String? phoneField(String? value) =>
    (value ?? '').replaceAll(RegExp(r'\D'), '').length < 10
    ? 'Telefone incompleto'
    : null;
String? cnpjField(String? value) =>
    (value ?? '').replaceAll(RegExp(r'\D'), '').length != 14
    ? 'CNPJ incompleto'
    : null;

String? cepField(String? value) =>
    (value ?? '').replaceAll(RegExp(r'\D'), '').length != 8
    ? 'CEP incompleto'
    : null;

/// CEP no perfil: postos cadastrados antes deste campo não têm um gravado, e
/// exigir preenchimento travaria até a edição de nome. Vazio passa; digitado
/// tem que estar completo.
String? optionalCepField(String? value) =>
    (value ?? '').trim().isEmpty ? null : cepField(value);

/// Número do imóvel: aceita "S/N" além de dígitos.
String? streetNumberField(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Informe o número (ou S/N)';
  if (text.length > 10) return 'Número muito longo';
  return null;
}
