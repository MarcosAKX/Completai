// Perfil do posto visto e editado pelo dono, unindo dados privados
// (`gas_stations/{uid}`) e públicos (`public_stations/{uid}`) num só objeto.
import '../../../../shared/models/station_brand.dart';
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
    required this.serviceCount,
    required this.openingHoursInformed,
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

  final String address;
  final String neighborhood;
  final String city;

  /// UF derivada da geocodificação; sempre `SP` no escopo atual.
  final String state;

  /// Preço por litro de cada combustível; `null` = não informado.
  final Map<StationFuel, double?> prices;

  /// Quantidade de serviços/comodidades cadastrados (a edição da lista em si
  /// virá na aba "Informações").
  final int serviceCount;

  /// Se ao menos um dia tem horário definido (a edição virá na aba
  /// "Horários"). Enquanto `false`, a prévia mostra "horário não informado".
  final bool openingHoursInformed;

  int get informedFuelCount =>
      prices.values.where((price) => price != null).length;

  double? priceFor(StationFuel fuel) => prices[fuel];

  StationProfile copyWith({
    String? name,
    String? phone,
    StationBrand? brand,
    String? address,
    String? neighborhood,
    String? city,
    String? state,
    Map<StationFuel, double?>? prices,
  }) => StationProfile(
    uid: uid,
    name: name ?? this.name,
    cnpj: cnpj,
    phone: phone ?? this.phone,
    email: email,
    brand: brand ?? this.brand,
    address: address ?? this.address,
    neighborhood: neighborhood ?? this.neighborhood,
    city: city ?? this.city,
    state: state ?? this.state,
    prices: prices ?? this.prices,
    serviceCount: serviceCount,
    openingHoursInformed: openingHoursInformed,
  );
}
