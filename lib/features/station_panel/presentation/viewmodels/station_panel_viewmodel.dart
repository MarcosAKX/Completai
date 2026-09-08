// Estado do painel do posto: carrega o perfil e persiste cada bloco editável.
// Sem import de Flutter — Dart puro, testável sem widget.
import 'dart:typed_data';

import 'package:riverpod/riverpod.dart';

import '../../../station_cover/domain/repositories/station_cover_repository.dart';
import '../../../station_cover/presentation/providers/station_cover_providers.dart';
import '../../../../shared/models/station_brand.dart';
import '../../domain/models/cover_edit.dart';
import '../../domain/models/opening_hours.dart';
import '../../domain/models/station_fuel.dart';
import '../../domain/models/station_profile.dart';
import '../../domain/repositories/station_panel_repository.dart';

class StationPanelViewModel extends AsyncNotifier<StationProfile> {
  StationPanelViewModel(this._repositoryProvider);

  final ProviderListenable<StationPanelRepository> _repositoryProvider;

  StationPanelRepository get _repository => ref.read(_repositoryProvider);
  StationCoverRepository get _coverRepository =>
      ref.read(stationCoverRepositoryProvider);

  @override
  Future<StationProfile> build() => _repository.loadProfile();

  Future<bool> reload() =>
      _run(() => _repository.loadProfile(forceRefresh: true));

  Future<bool> savePrices(Map<StationFuel, double?> prices) =>
      _run(() => _repository.savePrices(prices));

  Future<bool> saveIdentity({required String name, required String phone}) =>
      _run(() => _repository.saveIdentity(name: name, phone: phone));

  Future<bool> saveAddress({
    required String address,
    required String neighborhood,
    required String city,
  }) => _run(
    () => _repository.saveAddress(
      address: address,
      neighborhood: neighborhood,
      city: city,
    ),
  );

  /// Bandeira e foto são salvas juntas na tela "Editar exibição".
  ///
  /// Não é atômico: foto (`station_covers/{uid}`) e bandeira
  /// (`public_stations/{uid}`) são escritas separadas. Se a foto grava e a
  /// bandeira falha, a UI mostra erro mas a foto já foi. Aceitável no escopo
  /// atual — a foto é o que o dono acabou de escolher, não há perda de dado;
  /// no retry a bandeira também vai. Correção plena exigiria as duas no mesmo
  /// batch (hoje passam por serviços diferentes).
  Future<bool> saveDisplay({
    required StationBrand brand,
    CoverEditKind coverEdit = CoverEditKind.keep,
    Uint8List? coverBytes,
  }) => _run(() async {
    final current = state.requireValue;
    switch (coverEdit) {
      case CoverEditKind.replace:
        await _coverRepository.save(
          stationUid: current.uid,
          sourceBytes: coverBytes!,
        );
      case CoverEditKind.remove:
        await _coverRepository.remove(current.uid);
      case CoverEditKind.keep:
        break;
    }
    if (coverEdit != CoverEditKind.keep) {
      ref.invalidate(stationCoverProvider(current.uid));
    }
    if (brand == current.brand) return current;
    return _repository.saveBrand(brand);
  });

  Future<bool> saveInfo({
    required List<String> services,
    required List<String> tags,
  }) => _run(() => _repository.saveInfo(services: services, tags: tags));

  Future<bool> saveOpeningHours(WeeklyHours hours) =>
      _run(() => _repository.saveOpeningHours(hours));

  Future<bool> _run(Future<StationProfile> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncValue<StationProfile>.loading().copyWithPrevious(state);
    final result = await AsyncValue.guard(action);
    state = result;
    return !result.hasError;
  }
}
