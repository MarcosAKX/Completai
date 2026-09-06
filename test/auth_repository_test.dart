// Testa cache por UID, invalidação e tradução de erros
// do Repository concreto.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:completai/features/auth/data/services/auth_profile_service.dart';
import 'package:completai/features/auth/data/services/firebase_auth_service.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';

class TestUser implements User {
  TestUser(this.uid);

  @override
  final String uid;

  @override
  String get email => '$uid@example.com';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuthService implements FirebaseAuthService {
  @override
  User? currentUser = TestUser('a');

  bool admin = false;
  int accountCreations = 0;

  @override
  Future<bool> isAdmin({bool forceRefresh = false}) async => admin;

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  Future<User> createAccount({
    required String email,
    required String password,
  }) async {
    accountCreations++;

    return currentUser = TestUser('created');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestProfiles implements AuthProfileService {
  int reads = 0;
  Object? failure;

  @override
  Future<AuthProfileData> readProfile(String uid) async {
    reads++;

    if (failure != null) {
      throw failure!;
    }

    if (uid == 'a') {
      return const AuthProfileData(
        role: AccountRole.client,
        name: 'Marcos Antonio',
      );
    }

    return const AuthProfileData(role: AccountRole.gasStation);
  }

  @override
  Future<AccountRole?> readRole(String uid) async {
    return (await readProfile(uid)).role;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('cache evita leituras repetidas e nunca atravessa UIDs', () async {
    final auth = TestAuthService();
    final profiles = TestProfiles();

    final repository = AuthRepositoryImpl(auth, profiles);

    await repository.restoreSession();
    await repository.restoreSession();

    expect(profiles.reads, 1);

    auth.currentUser = TestUser('b');

    final session = await repository.restoreSession();

    expect(session!.uid, 'b');

    expect(session.role, AccountRole.gasStation);

    expect(profiles.reads, 2);
  });

  test('sessão do cliente recebe nome salvo no perfil', () async {
    final repository = AuthRepositoryImpl(TestAuthService(), TestProfiles());

    final session = await repository.restoreSession();

    expect(session, isNotNull);

    expect(session!.name, 'Marcos Antonio');

    expect(session.firstName, 'Marcos');
  });

  test('refresh explícito atualiza claim e logout limpa cache', () async {
    final auth = TestAuthService();
    final profiles = TestProfiles();

    final repository = AuthRepositoryImpl(auth, profiles);

    await repository.restoreSession();

    auth.admin = true;

    expect(
      (await repository.restoreSession(forceRefresh: true))!.isAdmin,
      isTrue,
    );

    await repository.signOut();

    expect(await repository.restoreSession(), isNull);

    auth.currentUser = TestUser('a');

    await repository.restoreSession();

    expect(profiles.reads, 3);
  });

  test('conflito do serviço é traduzido para falha de domínio', () async {
    final profiles = TestProfiles()..failure = const RoleConflictException();

    final repository = AuthRepositoryImpl(TestAuthService(), profiles);

    await expectLater(
      repository.restoreSession(),
      throwsA(isA<RoleConflictFailure>()),
    );
  });

  test('createAccount reutiliza usuário autenticado do mesmo e-mail', () async {
    final auth = TestAuthService();

    final repository = AuthRepositoryImpl(auth, TestProfiles());

    final result = await repository.createAccount(
      email: 'a@example.com',
      password: 'ignored',
    );

    expect(result.uid, 'a');

    expect(auth.accountCreations, 0);
  });

  test('createAccount rejeita e-mail diferente durante outra sessão', () async {
    final auth = TestAuthService();

    final repository = AuthRepositoryImpl(auth, TestProfiles());

    await expectLater(
      repository.createAccount(email: 'outro@example.com', password: 'ignored'),
      throwsA(isA<ValidationFailure>()),
    );

    expect(auth.accountCreations, 0);
  });
}
