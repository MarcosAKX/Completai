// Protege a estrutura principal da home do motorista.
import 'package:completai/features/station_discovery/domain/models/station_discovery_result.dart';
import 'package:completai/features/station_discovery/domain/repositories/station_discovery_repository.dart';
import 'package:completai/features/station_discovery/presentation/providers/station_discovery_providers.dart';
import 'package:completai/features/station_discovery/presentation/views/station_discovery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStationRepository implements StationDiscoveryRepository {
  @override
  Future<StationDiscoveryResult> loadCurrentCity({
    bool forceRefresh = false,
  }) async {
    return const StationDiscoveryResult(
      city: 'Bebedouro',
      stations: [],
    );
  }

  @override
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  }) async {
    return StationDiscoveryResult(
      city: city,
      stations: const [],
    );
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
        child: const MaterialApp(
          home: StationDiscoveryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Completai!'), findsOneWidget);

    expect(
      find.text('Tudo pronto para o seu próximo abastecimento.'),
      findsOneWidget,
    );

    // Cards superiores
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Meus abastecimentos'), findsOneWidget);
    expect(find.text('Postos favoritos'), findsOneWidget);

    // Controles que continuam existindo abaixo dos cards
    expect(find.text('Meu combustível'), findsOneWidget);
    expect(find.text('Filtros'), findsOneWidget);

    // Campo de busca
    expect(
      find.widgetWithText(
        TextField,
        'Buscar posto ou bairro',
      ),
      findsOneWidget,
    );
  });

  testWidgets('home continua permitindo atualização por gesto', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDiscoveryRepositoryProvider.overrideWithValue(
            _FakeStationRepository(),
          ),
        ],
        child: const MaterialApp(
          home: StationDiscoveryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byType(RefreshIndicator),
      findsOneWidget,
    );

    expect(
      find.byType(CustomScrollView),
      findsOneWidget,
    );
  });
}