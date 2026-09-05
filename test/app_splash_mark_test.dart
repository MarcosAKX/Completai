import 'package:completai/core/widgets/app_splash_hose_painter.dart';
import 'package:completai/core/widgets/app_splash_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash renderiza bomba, mangueira e mensagem', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppSplashMark())),
      ),
    );

    expect(find.byType(SplashHoseAnimation), findsOneWidget);
    expect(find.text('Completai!'), findsOneWidget);
    expect(find.text('Preparando seu próximo abastecimento'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });
}
