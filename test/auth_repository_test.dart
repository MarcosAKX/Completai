// Testa cache por UID, invalidação e tradução de erros do Repository concreto.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:completai/features/auth/data/services/firebase_auth_service.dart';
import 'package:completai/features/auth/data/services/auth_profile_service.dart';
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
  @override
  Future<bool> isAdmin({bool forceRefresh = false}) async => admin;
  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestProfiles implements AuthProfileService {
  int reads = 0;
  Object? failure;
  @override
  Future<AccountRole?> readRole(String uid) async {
    reads++;
    if (failure != null) throw failure!;
    return uid == 'a' ? AccountRole.client : AccountRole.gasStation;
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
}
