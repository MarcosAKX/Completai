// Abas Informações e Horários: renderização e persistência do que mudou.
import 'dart:typed_data';

import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/station_cover/domain/models/station_cover.dart';
import 'package:completai/features/station_cover/domain/repositories/station_cover_repository.dart';
import 'package:completai/features/station_cover/presentation/providers/station_cover_providers.dart';
import 'package:completai/features/station_panel/domain/models/opening_hours.dart';
import 'package:completai/features/station_panel/domain/models/station_fuel.dart';
import 'package:completai/features/station_panel/domain/models/station_profile.dart';
import 'package:completai/features/station_panel/domain/repositories/station_panel_repository.dart';
import 'package:completai/features/station_panel/presentation/providers/station_panel_providers.dart';
import 'package:completai/features/station_panel/presentation/views/station_hours_tab.dart';
import 'package:completai/features/station_panel/presentation/views/station_info_tab.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements StationPanelRepository {
  _FakeRepo(this._profile);
  StationProfile _profile;
  ({List<String> services, List<String> tags})? savedInfo;
  WeeklyHours? savedHours;

  @override
  Future<StationProfile> loadProfile({bool forceRefresh = false}) async =>
      _profile;

  @override
  Future<StationProfile> saveInfo({
    required List<String> services,
    required List<String> tags,
  }) async {
    savedInfo = (services: services, tags: tags);
    return _profile = _profile.copyWith(services: services, tags: tags);
  }

  @override
  Future<StationProfile> saveOpeningHours(WeeklyHours hours) async {
    savedHours = hours;
    return _profile = _profile.copyWith(openingHours: hours);
  }

  @override
  Future<StationProfile> savePrices(Map<StationFuel, double?> prices) async =>
      _profile;
  @override
  Future<StationProfile> saveIdentity({
    required String name,
    required String phone,
  }) async => _profile;
  @override
  Future<StationProfile> saveAddress({
    required String address,
    required String neighborhood,
    required String city,
  }) async => _profile;
  @override
  Future<StationProfile> saveBrand(StationBrand brand) async => _profile;
}

class _NoCover implements StationCoverRepository {
  @override
  Future<StationCover?> load(String stationUid) async => null;
  @override
  Future<void> save({
    required String stationUid,
    required Uint8List sourceBytes,
  }) async {}
  @override
  Future<void> remove(String stationUid) async {}
}

StationProfile _profile() => StationProfile(
  uid: 'station-1',
  name: 'Posto Teste',
  cnpj: '123',
  phone: '(17) 3333-4444',
  email: 'p@e.test',
  brand: StationBrand.branca,
  address: 'Rua 1',
  neighborhood: 'Centro',
  city: 'Bebedouro',
  state: 'SP',
  prices: {for (final fuel in StationFuel.values) fuel: null},
  services: const ['Conveniência'],
  tags: const [],
  openingHours: const WeeklyHours.empty(),
);

Future<(ProviderContainer, _FakeRepo)> _mount(
  WidgetTester tester,
  Widget child,
) async {
  final repo = _FakeRepo(_profile());
  final container = ProviderContainer(
    overrides: [
      stationPanelRepositoryProvider.overrideWithValue(repo),
      stationCoverRepositoryProvider.overrideWithValue(_NoCover()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(stationPanelViewModelProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
  return (container, repo);
}

void main() {
  testWidgets('Informações: liga um serviço e salva', (tester) async {
    final (_, repo) = await _mount(tester, const StationInfoTab());

    expect(find.text('Nada para salvar'), findsOneWidget);
    await tester.tap(find.text('GNV'));
    await tester.pump();
    expect(find.text('Salvar informações'), findsOneWidget);

    await tester.tap(find.text('Salvar informações'));
    await tester.pump();
    expect(repo.savedInfo?.services, containsAll(['Conveniência', 'GNV']));
  });

  testWidgets('Horários: abre um dia e salva', (tester) async {
    final (_, repo) = await _mount(tester, const StationHoursTab());

    expect(find.text('Segunda'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.text('Salvar horários'), findsOneWidget);

    await tester.tap(find.text('Salvar horários'));
    await tester.pump();
    expect(repo.savedHours!.isOpen(Weekday.monday), isTrue);
  });
}
