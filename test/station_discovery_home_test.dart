// Protege a estrutura principal da Home do motorista.
import 'package:completai/features/station_discovery/domain/models/station_discovery_result.dart';
import 'package:completai/features/station_discovery/domain/models/station_summary.dart';
import 'package:completai/features/station_discovery/domain/repositories/station_discovery_repository.dart';
import 'package:completai/features/station_discovery/presentation/providers/station_discovery_providers.dart';
import 'package:completai/features/station_discovery/presentation/views/station_discovery_page.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStationRepository implements StationDiscoveryRepository {
  @override
  Future<StationDiscoveryResult> loadCurrentCity({
    bool forceRefresh = false,
  }) async {
    return const StationDiscoveryResult(city: 'Bebedouro', stations: []);
  }

  @override
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  }) async {
    return StationDiscoveryResult(city: city, stations: const []);
  }

  @override
  Future<List<String>> loadAvailableCities({bool forceRefresh = false}) async {
    return const ['Barretos', 'Bebedouro'];
  }
}

class _FakeStationRepositoryWithStation implements StationDiscoveryRepository {
  static const station = StationSummary(
    uid: 'posto-1',
    name: 'Posto Avenida Central',
    brand: StationBrand.shell,
    neighborhood: 'Centro',
    city: 'Bebedouro',
    latitude: -20.949,
    longitude: -48.479,
    prices: {
      FuelType.gasoline: 5.79,
      FuelType.ethanol: 3.89,
      FuelType.diesel: 5.99,
    },
    averageRating: 4.7,
    reviewCount: 128,
    pricesUpdatedAt: null,
    todayHours: null,
    distanceKm: 1.8,
  );

  @override
  Future<StationDiscoveryResult> loadCurrentCity({
    bool forceRefresh = false,
  }) async {
    return const StationDiscoveryResult(city: 'Bebedouro', stations: [station]);
  }

  @override
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  }) async {
    return StationDiscoveryResult(city: city, stations: const [station]);
  }

  @override
  Future<List<String>> loadAvailableCities({bool forceRefresh = false}) async {
    return const ['Barretos', 'Bebedouro'];
  }
}

void main() {
  testWidgets('home exibe a nova estrutura principal', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDiscoveryRepositoryProvider.overrideWithValue(
            _FakeStationRepository(),
          ),
        ],
        child: const MaterialApp(home: StationDiscoveryPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Completai!'), findsOneWidget);

    expect(
      find.text('Tudo pronto para o seu próximo abastecimento.'),
      findsOneWidget,
    );

    expect(find.text('Filtros'), findsOneWidget);

    expect(find.text('Meus abastecimentos'), findsOneWidget);

    expect(find.text('Postos favoritos'), findsOneWidget);

    expect(find.text('Meu combustível'), findsOneWidget);

    expect(
      find.widgetWithText(TextField, 'Buscar posto ou bairro'),
      findsOneWidget,
    );

    // O switch antigo saiu da área de combustível.
    expect(find.text('Mostrar somente postos abertos'), findsNothing);
  });

  testWidgets('home continua permitindo atualização por gesto', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDiscoveryRepositoryProvider.overrideWithValue(
            _FakeStationRepository(),
          ),
        ],
        child: const MaterialApp(home: StationDiscoveryPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);

    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('card do posto mostra nome bandeira e distância sem bairro', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDiscoveryRepositoryProvider.overrideWithValue(
            _FakeStationRepositoryWithStation(),
          ),
        ],
        child: const MaterialApp(home: StationDiscoveryPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));

    await tester.pumpAndSettle();

    expect(find.text('Posto Avenida Central'), findsOneWidget);

    expect(find.text('Shell'), findsOneWidget);

    expect(find.text('1.8 km'), findsOneWidget);

    expect(find.text('Centro'), findsNothing);
  });

  testWidgets('filtros oferece distância avaliação e postos abertos', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDiscoveryRepositoryProvider.overrideWithValue(
            _FakeStationRepository(),
          ),
        ],
        child: const MaterialApp(home: StationDiscoveryPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Filtros'));

    await tester.pumpAndSettle();

    expect(find.text('Distância máxima'), findsOneWidget);

    expect(find.text('Qualquer'), findsOneWidget);

    expect(find.text('2 km'), findsOneWidget);

    expect(find.text('5 km'), findsOneWidget);

    expect(find.text('10 km'), findsOneWidget);

    expect(find.text('Avaliação mínima'), findsOneWidget);

    expect(find.text('Somente postos abertos'), findsOneWidget);

    expect(find.text('Limpar filtros'), findsOneWidget);

    expect(find.text('Aplicar'), findsOneWidget);
  });

  testWidgets('lista de postos permite escolher ordenação', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDiscoveryRepositoryProvider.overrideWithValue(
            _FakeStationRepositoryWithStation(),
          ),
        ],
        child: const MaterialApp(home: StationDiscoveryPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));

    await tester.pumpAndSettle();

    expect(find.text('Ordenar'), findsOneWidget);

    await tester.tap(find.text('Ordenar'));

    await tester.pumpAndSettle();

    expect(find.text('Menor preço'), findsWidgets);

    expect(find.text('Mais próximo'), findsOneWidget);

    expect(find.text('Melhor avaliação'), findsOneWidget);
  });

  testWidgets(
    'seletor de cidade mostra somente cidades com postos cadastrados',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stationDiscoveryRepositoryProvider.overrideWithValue(
              _FakeStationRepository(),
            ),
          ],
          child: const MaterialApp(home: StationDiscoveryPage()),
        ),
      );

      await tester.pumpAndSettle();

      final citySelector = find.textContaining('Bebedouro');

      expect(citySelector, findsWidgets);

      await tester.tap(citySelector.first);

      await tester.pumpAndSettle();

      expect(find.text('Escolher cidade'), findsOneWidget);

      expect(find.text('Barretos'), findsOneWidget);

      // Bebedouro aparece no seletor da Home e também
      // entre as cidades disponíveis.
      expect(find.text('Bebedouro'), findsWidgets);

      // O antigo campo de digitação não deve mais existir.
      expect(find.widgetWithText(TextField, 'Ex.: Bebedouro'), findsNothing);
    },
  );
}
