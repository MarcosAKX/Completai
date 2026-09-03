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
