import 'package:completai/features/fuel_discovery_prototype/presentation/views/fuel_discovery_prototype_page.dart';
import 'package:completai/features/fuel_discovery_prototype/presentation/widgets/fuel_prototype_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mockup cabe em 320x568 e abre painel do posto', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FuelDiscoveryPrototypePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Posto Avenida'));
    await tester.tap(find.text('Posto Avenida'));
    await tester.pumpAndSettle();
    expect(find.text('Painel do posto'), findsOneWidget);
  });

  testWidgets('swipe troca combustível e pull-to-refresh está disponível', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FuelDiscoveryPrototypePage()),
      ),
    );
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('⛽  Gasolina'), findsOneWidget);

    await tester.fling(
      find.byType(PrototypeFuelSelector),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('⛽  Etanol'), findsOneWidget);
  });
}
