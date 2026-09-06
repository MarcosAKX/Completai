// Contrato do painel do posto: carrega o perfil combinado e persiste cada
// bloco editável. A implementação cuida de batch, geocodificação e cache.
import '../../../../shared/models/station_brand.dart';
import '../models/station_fuel.dart';
import '../models/station_profile.dart';

abstract interface class StationPanelRepository {
  /// Perfil do posto do dono logado (`gas_stations` + `public_stations`).
  Future<StationProfile> loadProfile({bool forceRefresh = false});

  /// Publica os preços informados. `null` limpa o combustível.
  /// Atualiza `pricesUpdatedAt`.
  Future<StationProfile> savePrices(Map<StationFuel, double?> prices);

  /// Nome e telefone administrativo. Nome vai para as duas coleções (batch).
  Future<StationProfile> saveIdentity({
    required String name,
    required String phone,
  });

  /// Novo endereço: re-geocodifica, exige UF `SP` e regrava cidade canônica,
  /// chave de busca e coordenadas em `public_stations`.
  Future<StationProfile> saveAddress({
    required String address,
    required String neighborhood,
    required String city,
  });

  /// Bandeira exibida ao cliente.
  Future<StationProfile> saveBrand(StationBrand brand);
}
