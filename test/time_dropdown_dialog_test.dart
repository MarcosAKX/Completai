// Seletor de horário por listas: sem relógio analógico e sem digitar.
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/station_panel/presentation/widgets/time_dropdown_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<TimeOfDay?> _abrir(WidgetTester tester, TimeOfDay inicial) async {
  TimeOfDay? resultado;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              resultado = await TimeDropdownDialog.show(
                context,
                title: 'Fecha às — Domingo',
                initial: inicial,
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

void main() {
  testWidgets('abre mostrando o horário atual, sem relógio nem teclado', (
    tester,
  ) async {
    await _abrir(tester, const TimeOfDay(hour: 8, minute: 0));

    expect(find.text('Fecha às — Domingo'), findsOneWidget);
    expect(find.text('Hora'), findsOneWidget);
    expect(find.text('Minuto'), findsOneWidget);
    // Prévia do que será gravado, no mesmo formato do card.
    expect(find.text('08:00'), findsOneWidget);
    // Nenhum campo de texto: o pedido era não digitar.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('escolher 23 na lista de horas devolve 23:00', (tester) async {
    TimeOfDay? escolhido;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                escolhido = await TimeDropdownDialog.show(
                  context,
                  title: 'Fecha às — Domingo',
                  initial: const TimeOfDay(hour: 18, minute: 0),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('23').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(escolhido, const TimeOfDay(hour: 23, minute: 0));
  });

  testWidgets('cancelar não devolve horário', (tester) async {
    TimeOfDay? escolhido = const TimeOfDay(hour: 1, minute: 1);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                escolhido = await TimeDropdownDialog.show(
                  context,
                  title: 'Abre às — Segunda',
                  initial: const TimeOfDay(hour: 8, minute: 0),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(escolhido, isNull);
  });

  test('minuto fora da grade não some da lista', () {
    // Horário já gravado como 01:59 precisa continuar selecionável, senão
    // abrir o seletor perderia o valor do posto.
    expect(TimeDropdownDialog.minuteOptions(59), [0, 15, 30, 45, 59]);
    // Valor que já está na grade não duplica.
    expect(TimeDropdownDialog.minuteOptions(30), [0, 15, 30, 45]);
  });
}
