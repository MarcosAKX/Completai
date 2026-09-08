// Orquestra o serviço do painel: resolve o uid do dono, embrulha erros em
// `Failure`, aplica timeout e mantém o único cache do perfil em memória.
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../shared/models/station_brand.dart';
import '../../domain/models/opening_hours.dart';
import '../../domain/models/station_fuel.dart';
import '../../domain/models/station_profile.dart';
import '../../domain/repositories/station_panel_repository.dart';
import '../services/station_panel_service.dart';

class StationPanelRepositoryImpl implements StationPanelRepository {
  StationPanelRepositoryImpl(this._service, {required this.uidProvider});

  final StationPanelService _service;
  final String? Function() uidProvider;

  StationProfile? _cache;

  String _requireUid() =>
      uidProvider() ?? (throw const UnauthenticatedException());

  @override
  Future<StationProfile> loadProfile({bool forceRefresh = false}) async {
    final cached = _cache;
    if (!forceRefresh && cached != null) return cached;
    return _reload();
  }

  Future<StationProfile> _reload() async {
    final uid = _requireUid();
    final profile = await guardInfra(() => _service.read(uid));
    return _cache = profile;
  }

  @override
  Future<StationProfile> savePrices(Map<StationFuel, double?> prices) async {
    final uid = _requireUid();
    await guardInfra(() => _service.writePrices(uid, prices));
    return _reload();
  }

  @override
  Future<StationProfile> saveIdentity({
    required String name,
    required String phone,
  }) async {
    final uid = _requireUid();
    await guardInfra(() => _service.writeIdentity(uid, name, phone));
    return _reload();
  }

  @override
  Future<StationProfile> saveAddress({
    required String address,
    required String neighborhood,
    required String city,
  }) async {
    final uid = _requireUid();
    await guardInfra(
      () => _service.writeAddress(uid, address, neighborhood, city),
    );
    return _reload();
  }

  @override
  Future<StationProfile> saveBrand(StationBrand brand) async {
    final uid = _requireUid();
    await guardInfra(() => _service.writeBrand(uid, brand));
    return _reload();
  }

  @override
  Future<StationProfile> saveInfo({
    required List<String> services,
    required List<String> tags,
  }) async {
    final uid = _requireUid();
    await guardInfra(() => _service.writeInfo(uid, services, tags));
    return _reload();
  }

  @override
  Future<StationProfile> saveOpeningHours(WeeklyHours hours) async {
    final uid = _requireUid();
    await guardInfra(() => _service.writeOpeningHours(uid, hours));
    return _reload();
  }
}
