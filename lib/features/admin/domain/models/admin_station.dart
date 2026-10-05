// Posto como o administrador precisa vê-lo: dados públicos + os privados
// necessários para conferir se o cadastro é legítimo.
//
// Junta `public_stations/{uid}` (endereço, bandeira, situação) com
// `gas_stations/{uid}` (CNPJ, e-mail, telefone administrativo). A leitura do
// documento privado pelo admin é uma permissão concedida de propósito — ver
// ADMIN.md, seção "Por que o admin lê dado privado".
import '../../../../shared/models/station_brand.dart';
import '../../../../shared/models/station_approval_status.dart';

class AdminStation {
  const AdminStation({
    required this.uid,
    required this.name,
    required this.status,
    required this.brand,
    required this.address,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.cep = '',
    this.cnpj = '',
    this.email = '',
    this.phone = '',
    this.createdAt,
    this.privateDataMissing = false,
  });

  final String uid;
  final String name;
  final StationApprovalStatus status;
  final StationBrand brand;

  final String address;
  final String neighborhood;
  final String city;
  final String state;

  /// Só dígitos, como está no documento.
  final String cep;

  // --- vindos de gas_stations/{uid} ---
  final String cnpj;
  final String email;
  final String phone;
  final DateTime? createdAt;

  /// `gas_stations/{uid}` não existe ou não pôde ser lido. O admin ainda vê
  /// o posto, com aviso — melhor do que a fila sumir por causa de um
  /// documento quebrado.
  final bool privateDataMissing;

  String get location => [
    address,
    neighborhood,
    city,
  ].where((part) => part.trim().isNotEmpty).join(' • ');

  /// CNPJ com máscara, só para exibição.
  String get cnpjFormatted {
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return cnpj.isEmpty ? '—' : cnpj;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
        '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
        '${digits.substring(12)}';
  }

  String get cepFormatted {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return digits.isEmpty ? '—' : cep;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }
}
