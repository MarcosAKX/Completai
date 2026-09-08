// ViewModel do painel do posto: carga, publicação de preços, exibição e erros.
import 'dart:typed_data';

import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/station_cover/domain/models/station_cover.dart';
import 'package:completai/features/station_cover/domain/repositories/station_cover_repository.dart';
import 'package:completai/features/station_cover/presentation/providers/station_cover_providers.dart';
import 'package:completai/features/station_panel/domain/models/cover_edit.dart';
import 'package:completai/features/station_panel/domain/models/opening_hours.dart';
import 'package:completai/features/station_panel/domain/models/station_fuel.dart';
import 'package:completai/features/station_panel/domain/models/station_profile.dart';
import 'package:completai/features/station_panel/domain/repositories/station_panel_repository.dart';
import 'package:completai/features/station_panel/presentation/providers/station_panel_providers.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

StationProfile _profile({
  StationBrand brand = StationBrand.branca,
  Map<StationFuel, double?>? prices,
}) => StationProfile(
  uid: 'station-1',
  name: 'Posto Teste',
  cnpj: '12.345.678/0001-90',
  phone: '(17) 3333-4444',
  email: 'posto@example.test',
  brand: brand,
  address: 'Rua 1, 100',
  neighborhood: 'Centro',
  city: 'Bebedouro',
  state: 'SP',
  prices: prices ?? {for (final fuel in StationFuel.values) fuel: null},
  services: const [],
  tags: const [],
  openingHours: const WeeklyHours.empty(),
);

class FakePanelRepository implements StationPanelRepository {
  FakePanelRepository(this._profile);
  StationProfile _profile;
  Failure? failWith;
  Map<StationFuel, double?>? savedPrices;
  StationBrand? savedBrand;
  ({String address, String neighborhood, String city})? savedAddress;
  ({String name, String phone})? savedIdentity;
  ({List<String> services, List<String> tags})? savedInfo;
  WeeklyHours? savedHours;

  @override
  Future<StationProfile> loadProfile({bool forceRefresh = false}) async =>
      _profile;

  @override
  Future<StationProfile> savePrices(Map<StationFuel, double?> prices) async {
    if (failWith != null) throw failWith!;
    savedPrices = prices;
    return _profile = _profile.copyWith(
      prices: {..._profile.prices, ...prices},
    );
  }

  @override
  Future<StationProfile> saveIdentity({
    required String name,
    required String phone,
  }) async {
    if (failWith != null) throw failWith!;
    savedIdentity = (name: name, phone: phone);
    return _profile = _profile.copyWith(name: name, phone: phone);
  }

  @override
  Future<StationProfile> saveAddress({
    required String address,
    required String neighborhood,
    required String city,
  }) async {
    if (failWith != null) throw failWith!;
    savedAddress = (address: address, neighborhood: neighborhood, city: city);
    return _profile = _profile.copyWith(
      address: address,
      neighborhood: neighborhood,
      city: city,
    );
  }

  @override
  Future<StationProfile> saveBrand(StationBrand brand) async {
    if (failWith != null) throw failWith!;
    savedBrand = brand;
    return _profile = _profile.copyWith(brand: brand);
  }

  @override
  Future<StationProfile> saveInfo({
    required List<String> services,
    required List<String> tags,
  }) async {
    if (failWith != null) throw failWith!;
    savedInfo = (services: services, tags: tags);
    return _profile = _profile.copyWith(services: services, tags: tags);
  }

  @override
  Future<StationProfile> saveOpeningHours(WeeklyHours hours) async {
    if (failWith != null) throw failWith!;
    savedHours = hours;
    return _profile = _profile.copyWith(openingHours: hours);
  }
}

class FakeCoverRepository implements StationCoverRepository {
  int saves = 0;
  int removes = 0;

  @override
  Future<StationCover?> load(String stationUid) async => null;

  @override
  Future<void> save({
    required String stationUid,
    required Uint8List sourceBytes,
  }) async => saves++;

  @override
  Future<void> remove(String stationUid) async => removes++;
}

ProviderContainer _container(
  FakePanelRepository panel,
  FakeCoverRepository cover,
) {
  final container = ProviderContainer(
    overrides: [
      stationPanelRepositoryProvider.overrideWithValue(panel),
      stationCoverRepositoryProvider.overrideWithValue(cover),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('carrega o perfil do posto', () async {
    final container = _container(
      FakePanelRepository(_profile(brand: StationBrand.shell)),
      FakeCoverRepository(),
    );
    final profile = await container.read(
      stationPanelViewModelProvider.future,
    );
    expect(profile.brand, StationBrand.shell);
  });

  test('publica apenas os preços informados', () async {
    final panel = FakePanelRepository(_profile());
    final container = _container(panel, FakeCoverRepository());
    await container.read(stationPanelViewModelProvider.future);

    final ok = await container
        .read(stationPanelViewModelProvider.notifier)
        .savePrices({StationFuel.ethanol: 3.999});

    expect(ok, isTrue);
    expect(panel.savedPrices, {StationFuel.ethanol: 3.999});
    expect(
      container.read(stationPanelViewModelProvider).requireValue.priceFor(
        StationFuel.ethanol,
      ),
      3.999,
    );
  });

  test('falha ao publicar mantém erro no estado', () async {
    final panel = FakePanelRepository(_profile())
      ..failWith = const NetworkFailure('sem rede');
    final container = _container(panel, FakeCoverRepository());
    await container.read(stationPanelViewModelProvider.future);

    final ok = await container
        .read(stationPanelViewModelProvider.notifier)
        .savePrices({StationFuel.gasolineRegular: 6.29});

    expect(ok, isFalse);
    expect(container.read(stationPanelViewModelProvider).hasError, isTrue);
  });

  test('salvar exibição troca foto e bandeira juntas', () async {
    final panel = FakePanelRepository(_profile());
    final cover = FakeCoverRepository();
    final container = _container(panel, cover);
    await container.read(stationPanelViewModelProvider.future);

    final ok = await container
        .read(stationPanelViewModelProvider.notifier)
        .saveDisplay(
          brand: StationBrand.ipiranga,
          coverEdit: CoverEditKind.replace,
          coverBytes: Uint8List.fromList([1, 2, 3]),
        );

    expect(ok, isTrue);
    expect(cover.saves, 1);
    expect(panel.savedBrand, StationBrand.ipiranga);
  });

  test('salvar exibição sem mudar bandeira não chama saveBrand', () async {
    final panel = FakePanelRepository(_profile(brand: StationBrand.ale));
    final cover = FakeCoverRepository();
    final container = _container(panel, cover);
    await container.read(stationPanelViewModelProvider.future);

    await container
        .read(stationPanelViewModelProvider.notifier)
        .saveDisplay(brand: StationBrand.ale, coverEdit: CoverEditKind.remove);

    expect(cover.removes, 1);
    expect(panel.savedBrand, isNull);
  });

  test('salvar endereço encaminha os campos ao repositório', () async {
    final panel = FakePanelRepository(_profile());
    final container = _container(panel, FakeCoverRepository());
    await container.read(stationPanelViewModelProvider.future);

    await container
        .read(stationPanelViewModelProvider.notifier)
        .saveAddress(
          address: 'Av. Nova, 200',
          neighborhood: 'Jardim',
          city: 'Barretos',
        );

    expect(panel.savedAddress?.city, 'Barretos');
  });

  test('salvar informações encaminha serviços e marcadores', () async {
    final panel = FakePanelRepository(_profile());
    final container = _container(panel, FakeCoverRepository());
    await container.read(stationPanelViewModelProvider.future);

    final ok = await container
        .read(stationPanelViewModelProvider.notifier)
        .saveInfo(services: ['Conveniência', 'GNV'], tags: ['24 horas']);

    expect(ok, isTrue);
    expect(panel.savedInfo?.services, ['Conveniência', 'GNV']);
    expect(panel.savedInfo?.tags, ['24 horas']);
  });

  test('salvar horários encaminha a semana ao repositório', () async {
    final panel = FakePanelRepository(_profile());
    final container = _container(panel, FakeCoverRepository());
    await container.read(stationPanelViewModelProvider.future);

    final hours = const WeeklyHours.empty().withDay(
      Weekday.monday,
      const DayHours(open: '08:00', close: '18:00'),
    );
    final ok = await container
        .read(stationPanelViewModelProvider.notifier)
        .saveOpeningHours(hours);

    expect(ok, isTrue);
    expect(panel.savedHours, hours);
  });
}
