// Dados mínimos de cadastro; preços e horários começam sem informação.
class StationRegistration {
  const StationRegistration({
    required this.cnpj,
    required this.brandName,
    required this.phone,
    required this.address,
    required this.neighborhood,
    required this.city,
  });

  final String cnpj;
  final String brandName;
  final String phone;
  final String address;
  final String neighborhood;
  final String city;
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
