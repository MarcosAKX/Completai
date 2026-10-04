// Dados mínimos de cadastro; preços e horários começam sem informação.
class StationRegistration {
  const StationRegistration({
    required this.cnpj,
    required this.brandName,
    required this.phone,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    this.cep = '',
  });

  final String cnpj;
  final String brandName;
  final String phone;

  /// Rua/avenida, sem o número.
  final String street;

  /// Número do imóvel — aceita "S/N".
  final String number;

  final String neighborhood;
  final String city;

  /// CEP como digitado. Opcional: melhora a precisão da geocodificação.
  final String cep;
}

// Dados da primeira etapa, mantidos somente em memória até a confirmação final.
class StationRegistrationDraft {
  const StationRegistrationDraft({
    required this.brandName,
    required this.cnpj,
    required this.phone,
    required this.email,
    required this.password,
  });
  final String brandName;
  final String cnpj;
  final String phone;
  final String email;
  final String password;
}
