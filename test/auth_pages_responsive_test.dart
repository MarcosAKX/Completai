// Protege o fluxo visual contra overflow em aparelhos Android pequenos.
import 'package:completai/core/utils/contact_input_formatters.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/domain/models/station_registration.dart';
import 'package:completai/features/auth/domain/repositories/auth_repository.dart';
import 'package:completai/features/auth/presentation/providers/auth_providers.dart';
import 'package:completai/features/auth/presentation/views/client_registration_page.dart';
import 'package:completai/features/auth/presentation/views/forgot_password_page.dart';
import 'package:completai/features/auth/presentation/views/login_page.dart';
import 'package:completai/features/auth/presentation/views/role_selection_page.dart';
import 'package:completai/features/auth/presentation/views/station_registration_step1_page.dart';
import 'package:completai/features/auth/presentation/views/station_registration_step2_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession({bool forceRefresh = false}) async =>
      null;
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async => AuthSession(uid: 'u1', email: email);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const draft = StationRegistrationDraft(
  brandName: 'Posto Teste',
  cnpj: '12.345.678/0001-90',
  phone: '(17) 3333-4444',
  email: 'posto@example.com',
  password: 'senha123',
);

Future<void> pumpSmall(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpPushedPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => page),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  final pages = <String, Widget>{
    'login': const LoginPage(),
    'recuperação': const ForgotPasswordPage(),
    'seleção de papel': const RoleSelectionPage(),
    'cadastro de cliente': const ClientRegistrationPage(),
    'cadastro de posto etapa 1': const StationRegistrationStep1Page(),
    'cadastro de posto etapa 2': const StationRegistrationStep2Page(
      draft: draft,
    ),
  };

  for (final entry in pages.entries) {
    testWidgets('${entry.key} cabe em 320x568 e permite rolagem', (
      tester,
    ) async {
      await pumpSmall(tester, entry.value);
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -500),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('login alterna a visibilidade da senha', (tester) async {
    await pumpSmall(tester, const LoginPage());
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isTrue,
    );
    await tester.ensureVisible(find.byTooltip('Mostrar senha'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isFalse,
    );
  });

  testWidgets('cadastro não fecha durante inicialização do ViewModel', (
    tester,
  ) async {
    await pumpPushedPage(tester, const ClientRegistrationPage());

    expect(find.byType(ClientRegistrationPage), findsOneWidget);
    expect(find.text('Torne-se um Usuário'), findsOneWidget);
  });

  testWidgets('recuperação não anuncia sucesso antes do envio', (tester) async {
    await pumpPushedPage(tester, const ForgotPasswordPage());

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
    expect(
      find.text('Enviamos as instruções para o seu e-mail.'),
      findsNothing,
    );
  });

  test('máscaras formatam celular e CNPJ sem pacote externo', () {
    const old = TextEditingValue.empty;
    expect(
      phoneInputFormatter
          .formatEditUpdate(old, const TextEditingValue(text: '17999998888'))
          .text,
      '(17) 99999-8888',
    );
    expect(
      cnpjInputFormatter
          .formatEditUpdate(old, const TextEditingValue(text: '12345678000190'))
          .text,
      '12.345.678/0001-90',
    );
  });
}
