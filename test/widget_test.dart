// Verifica controles ocupados e validação de formulário.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/core/widgets/app_button.dart';
import 'package:completai/core/widgets/app_text_field.dart';

void main() {
  testWidgets('botão ocupado não aceita novo acionamento', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Entrar',
            isLoading: true,
            onPressed: () => calls++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Entrar'));
    expect(calls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  testWidgets('campo exibe falha de validação e protege senha', (tester) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Form(
            key: form,
            child: AppTextField(
              label: 'Senha',
              obscureText: true,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Informe a senha' : null,
            ),
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Informe a senha'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
  });
}
