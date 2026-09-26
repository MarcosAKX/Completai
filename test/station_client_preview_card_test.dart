// "Prévia para clientes": também mostra se o posto está aberto agora,
// usando o mesmo cálculo compartilhado da Home/detalhe/favoritos.
import 'dart:typed_data';

import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/station_cover/domain/models/station_cover.dart';
import 'package:completai/features/station_cover/domain/repositories/station_cover_repository.dart';
import 'package:completai/features/station_cover/presentation/providers/station_cover_providers.dart';
import 'package:completai/features/station_panel/domain/models/opening_hours.dart';
import 'package:completai/features/station_panel/domain/models/station_fuel.dart';
import 'package:completai/features/station_panel/domain/models/station_profile.dart';
import 'package:completai/features/station_panel/presentation/widgets/station_client_preview_card.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

StationProfile _profile(WeeklyHours hours) => StationProfile(
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
  openingHours: hours,
);

Future<void> _pump(WidgetTester tester, StationProfile profile) async {
  final container = ProviderContainer(
    overrides: [
      stationCoverRepositoryProvider.overrideWithValue(_NoCoverRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: StationClientPreviewCard(profile: profile)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra "aberto" quando o horário cobre 24 horas', (
    tester,
  ) async {
    final hours = const WeeklyHours.empty().filledWith(
      const DayHours(open: '00:00', close: '00:00'),
    );
    await _pump(tester, _profile(hours));

    expect(find.textContaining('Aberto'), findsOneWidget);
    expect(find.textContaining('Fechado'), findsNothing);
  });

  testWidgets('mostra "fechado" quando nenhum dia está configurado', (
    tester,
  ) async {
    await _pump(tester, _profile(const WeeklyHours.empty()));

    expect(find.textContaining('Fechado'), findsOneWidget);
  });
}
