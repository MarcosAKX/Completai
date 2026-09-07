// Média visual: cinco posições, suporte a meia estrela e teto em cinco.
import 'package:completai/features/station_details/presentation/widgets/average_star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('média 4.5 mostra quatro estrelas inteiras e uma meia', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AverageStarRating(value: 4.5)),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    expect(find.bySemanticsLabel('Média 4,5 de 5 estrelas'), findsOneWidget);
  });

  testWidgets('valor acima de cinco permanece limitado a cinco estrelas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AverageStarRating(value: 7)),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    expect(find.bySemanticsLabel('Média 5,0 de 5 estrelas'), findsOneWidget);
  });
}
