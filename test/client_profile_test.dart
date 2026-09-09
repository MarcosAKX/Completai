// Contratos de persistência, sincronização da sessão e layout do perfil.
import 'package:completai/core/errors/failures.dart';
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/presentation/providers/auth_providers.dart';
import 'package:completai/features/auth/presentation/viewmodels/session_viewmodel.dart';
import 'package:completai/features/client_profile/data/repositories/client_profile_repository_impl.dart';
import 'package:completai/features/client_profile/data/services/client_profile_service.dart';
import 'package:completai/features/client_profile/domain/models/client_profile.dart';
import 'package:completai/features/client_profile/domain/repositories/client_profile_repository.dart';
import 'package:completai/features/client_profile/presentation/providers/client_profile_providers.dart';
import 'package:completai/features/client_profile/presentation/views/client_profile_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_viewmodel_test.dart' show TestAuthRepository;

class ProfileRepository implements ClientProfileRepository {
  ProfileRepository(this.auth);
  final TestAuthRepository auth;
  bool fail = false;
  ClientProfile profile = const ClientProfile(
    uid: 'client',
    name: 'Marcos Almeida',
    email: 'marcos@exemplo.com',
    phone: '17999999999',
  );
  @override
  Future<ClientProfile> load(String uid) async => profile;
  @override
  Future<ClientProfile> save(
    String uid, {
    required String name,
    required String phone,
  }) async {
    if (fail) throw const NetworkFailure('Sem conexão');
    profile = ClientProfile(
      uid: uid,
      name: name,
      phone: phone,
      email: profile.email,
    );
    auth.session = AuthSession(
      uid: uid,
      name: name,
      email: profile.email,
      role: AccountRole.client,
    );
    return profile;
  }
}

void main() {
  test(
    'edição preserva email, papel, uid e criação; rejeita telefone inválido',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('client').set({
        'uid': 'client',
        'type': 'client',
        'name': 'Marcos',
        'email': 'm@exemplo.com',
        'phone': '17999999999',
        'createdAt': 'preservado',
      });
      final repo = ClientProfileRepositoryImpl(ClientProfileService(db));
      await repo.save(
        'client',
        name: '  Marcos Almeida  ',
        phone: '(17) 98888-7777',
      );
      final data = (await db.collection('users').doc('client').get()).data()!;
      expect(data['name'], 'Marcos Almeida');
      expect(data['phone'], '17988887777');
      expect(data['email'], 'm@exemplo.com');
      expect(data['type'], 'client');
      expect(data['createdAt'], 'preservado');
      await expectLater(
        repo.save('client', name: 'Marcos', phone: '123'),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );

  test(
    'ViewModel atualiza saudação e preserva perfil quando salvar falha',
    () async {
      final auth = TestAuthRepository()
        ..session = const AuthSession(
          uid: 'client',
          email: 'm@exemplo.com',
          role: AccountRole.client,
        );
      final repo = ProfileRepository(auth);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          clientProfileRepositoryProvider.overrideWithValue(repo),
          sessionViewModelProvider.overrideWith(
            () => SessionViewModel(authRepositoryProvider),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = clientProfileViewModelProvider('client');
      container.listen(provider, (_, _) {});
      await container.read(sessionViewModelProvider.future);
      await container.read(provider.future);
      expect(
        await container
            .read(provider.notifier)
            .save(name: 'Novo Nome', phone: '17999999999'),
        isTrue,
      );
      expect(
        container.read(sessionViewModelProvider).requireValue!.name,
        'Novo Nome',
      );
      repo.fail = true;
      expect(
        await container
            .read(provider.notifier)
            .save(name: 'Outro', phone: '17999999999'),
        isFalse,
      );
      expect(container.read(provider).hasError, isTrue);
      expect(container.read(provider).valueOrNull!.name, 'Novo Nome');
    },
  );

  testWidgets('perfil em 320x568 abre edição e salva sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = TestAuthRepository()
      ..session = const AuthSession(
        uid: 'client',
        email: 'marcos@exemplo.com',
        name: 'Marcos Almeida',
        role: AccountRole.client,
      );
    final repo = ProfileRepository(auth);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          clientProfileRepositoryProvider.overrideWithValue(repo),
          sessionViewModelProvider.overrideWith(
            () => SessionViewModel(authRepositoryProvider),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ClientProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Editar meus dados'));
    await tester.tap(find.text('Editar meus dados'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).first, 'Marcos Novo');
    await tester.ensureVisible(find.text('Salvar alterações'));
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(find.text('Marcos Novo'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Redefinir senha'));
    await tester.tap(find.text('Redefinir senha'));
    await tester.pumpAndSettle();
    expect(auth.passwordResetRequests, 1);
    expect(tester.takeException(), isNull);
  });
}
