// Aba de preços: campos por combustível e contagem no botão de publicar.
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
import 'package:completai/features/station_panel/presentation/views/station_prices_tab.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubPanelRepository implements StationPanelRepository {
  Map<StationFuel, double?>? published;

  StationProfile get _profile => StationProfile(
    uid: 'station-1',
    name: 'Posto Teste',
    cnpj: '12345678000190',
    phone: '(17) 3333-4444',
    email: 'p@e.test',
    brand: StationBrand.branca,
    address: 'Rua 1',
    neighborhood: 'Centro',
    city: 'Bebedouro',
    state: 'SP',
    prices: {for (final fuel in StationFuel.values) fuel: null},
    services: const [],
    tags: const [],
    openingHours: const WeeklyHours.empty(),
  );

  @override
  Future<StationProfile> loadProfile({bool forceRefresh = false}) async =>
      _profile;

  @override
  Future<StationProfile> savePrices(Map<StationFuel, double?> prices) async {
    published = prices;
    return _profile;
  }

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

  @override
  Future<StationProfile> saveInfo({
    required List<String> services,
    required List<String> tags,
  }) async => _profile;

  @override
  Future<StationProfile> saveOpeningHours(WeeklyHours hours) async => _profile;
}

class _NoCoverRepository implements StationCoverRepository {
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

void main() {
  testWidgets('mostra 5 combustíveis e conta os preços alterados', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        stationPanelRepositoryProvider.overrideWithValue(
          _StubPanelRepository(),
        ),
        stationCoverRepositoryProvider.overrideWithValue(_NoCoverRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(stationPanelViewModelProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: StationPricesTab()),
        ),
      ),
    );
    await tester.pump();

    final scrollable = find.byType(Scrollable).first;
    for (final fuel in StationFuel.values) {
      await tester.scrollUntilVisible(
        find.text(fuel.label),
        180,
        scrollable: scrollable,
      );
      expect(find.text(fuel.label), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.text('Nenhum preço alterado'),
      180,
      scrollable: scrollable,
    );
    expect(find.text('Nenhum preço alterado'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(StationFuel.gasolineRegular.label),
      -180,
      scrollable: scrollable,
    );
    await tester.enterText(find.byType(TextFormField).first, '6,29');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Publicar 1 preço'),
      180,
      scrollable: scrollable,
    );
    expect(find.text('Publicar 1 preço'), findsOneWidget);
  });
}
