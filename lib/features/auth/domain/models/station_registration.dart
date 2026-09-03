// Dados mínimos de cadastro; preços e horários começam sem informação.
class StationRegistration {
  const StationRegistration({
    required this.cnpj,
    required this.brandName,
    required this.address,
  });

  final String cnpj;
  final String brandName;
  final String address;
}
