// Garante que o seletor tenha presença visual e área de toque confortável.
import 'package:completai/features/station_discovery/domain/models/station_discovery_result.dart';
import 'package:completai/features/station_discovery/domain/models/station_summary.dart';
import 'package:completai/features/station_discovery/domain/repositories/station_discovery_repository.dart';
import 'package:completai/features/station_discovery/presentation/providers/station_discovery_providers.dart';
import 'package:completai/features/station_discovery/presentation/views/station_discovery_page.dart';
import 'package:completai/features/station_discovery/presentation/widgets/station_fuel_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements StationDiscoveryRepository {
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

void main() {
  testWidgets('exibe três opções amplas com ícone e seleção evidente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StationFuelSelector(
            selected: FuelType.gasoline,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(StationFuelOption), findsNWidgets(3));

    expect(find.byIcon(Icons.local_gas_station_outlined), findsNWidgets(3));

    expect(
      tester.getSize(find.byType(StationFuelOption).first).height,
      greaterThanOrEqualTo(64),
    );

    expect(
      find.byKey(const ValueKey('fuel-selected-gasoline')),
      findsOneWidget,
    );
  });

  testWidgets('arrasto da direita para esquerda avança para etanol', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDiscoveryRepositoryProvider.overrideWithValue(_Repository()),
        ],
        child: const MaterialApp(home: StationDiscoveryPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fuel-selected-gasoline')),
      findsOneWidget,
    );

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(-300, 0),
      1000,
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fuel-selected-ethanol')), findsOneWidget);
  });
}
