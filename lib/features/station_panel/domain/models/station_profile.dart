// Perfil do posto visto e editado pelo dono, unindo dados privados
// (`gas_stations/{uid}`) e públicos (`public_stations/{uid}`) num só objeto.
import '../../../../shared/models/station_brand.dart';
import 'opening_hours.dart';
import 'station_fuel.dart';

class StationProfile {
  const StationProfile({
    required this.uid,
    required this.name,
    required this.cnpj,
    required this.phone,
    required this.email,
    required this.brand,
    required this.address,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.prices,
    required this.services,
    required this.tags,
    required this.openingHours,
    this.street = '',
    this.number = '',
    this.cep = '',
  });

  final String uid;

  /// Nome do posto (`brandName`). Vive em `gas_stations` e `public_stations`.
  final String name;

  /// Somente leitura nesta tela — o CNPJ não muda depois do cadastro.
  final String cnpj;

  /// Telefone administrativo (`gas_stations.phone`), não é público.
  final String phone;
  final String email;

  final StationBrand brand;

  /// Linha pronta para exibição ("Avenida Brasil, 1000"), composta a partir
  /// de [street] e [number]. Mantida porque é o que o cliente lê.
  final String address;

  /// Rua/avenida sem o número. Vazio em postos anteriores ao campo — nesse
  /// caso a tela deriva de [address] com `StationAddressInput.splitLegacyLine`.
  final String street;

  /// Número do imóvel — aceita "S/N". Vazio em postos antigos.
  final String number;

  /// CEP só com dígitos. Vazio quando o dono não informou.
  final String cep;

  final String neighborhood;
  final String city;

  /// UF derivada da geocodificação; sempre `SP` no escopo atual.
  final String state;

  /// Preço por litro de cada combustível; `null` = não informado.
  final Map<StationFuel, double?> prices;

  /// Serviços/comodidades exibidos ao cliente.
  final List<String> services;

  /// Marcadores livres do posto.
  final List<String> tags;

  final WeeklyHours openingHours;

  int get informedFuelCount =>
      prices.values.where((price) => price != null).length;

  int get serviceCount => services.length;

  bool get openingHoursInformed => openingHours.anyInformed;

  double? priceFor(StationFuel fuel) => prices[fuel];

  StationProfile copyWith({
    String? name,
    String? phone,
    StationBrand? brand,
    String? address,
    String? street,
    String? number,
    String? cep,
    String? neighborhood,
    String? city,
    String? state,
    Map<StationFuel, double?>? prices,
    List<String>? services,
    List<String>? tags,
    WeeklyHours? openingHours,
  }) => StationProfile(
    uid: uid,
    name: name ?? this.name,
    cnpj: cnpj,
    phone: phone ?? this.phone,
    email: email,
    brand: brand ?? this.brand,
    address: address ?? this.address,
    street: street ?? this.street,
    number: number ?? this.number,
    cep: cep ?? this.cep,
    neighborhood: neighborhood ?? this.neighborhood,
    city: city ?? this.city,
    state: state ?? this.state,
    prices: prices ?? this.prices,
    services: services ?? this.services,
    tags: tags ?? this.tags,
    openingHours: openingHours ?? this.openingHours,
  );
}
