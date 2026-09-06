// Protege a estrutura principal da home do motorista.
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

    // A lista fica mais abaixo na Home.
    // Como o SliverList cria os cards somente quando entram na tela,
    // rolamos a página antes de procurar o posto.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));

    await tester.pumpAndSettle();

    expect(find.text('Posto Avenida Central'), findsOneWidget);

    expect(find.text('Shell'), findsOneWidget);

    expect(find.text('1.8 km'), findsOneWidget);

    // O bairro não deve mais aparecer no card da listagem.
    expect(find.text('Centro'), findsNothing);
  });
}
