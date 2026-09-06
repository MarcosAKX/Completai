// Marca do posto: iniciais, palavra única e fallback de ícone.
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/core/widgets/station_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String name) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: StationLogo(stationName: name))),
  ),
);

void main() {
  testWidgets('duas palavras viram duas iniciais', (tester) async {
    await _pump(tester, 'Auto Posto Silva');
    expect(find.text('AP'), findsOneWidget);
  });

  testWidgets('palavra única vira uma inicial', (tester) async {
    await _pump(tester, 'posto1');
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('nome vazio cai no ícone de posto', (tester) async {
    await _pump(tester, '   ');
    expect(find.text(''), findsNothing);
    expect(find.byIcon(Icons.local_gas_station_outlined), findsOneWidget);
  });

  testWidgets('anuncia como imagem com rótulo acessível', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, 'Posto Central');
    expect(
      tester.getSemantics(find.byType(StationLogo)),
      containsSemantics(label: 'Logo de Posto Central', isImage: true),
    );
    handle.dispose();
  });
}
