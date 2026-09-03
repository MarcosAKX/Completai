// Verifica transições da ViewModel e propagação de falhas sem Firebase real.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/domain/repositories/auth_repository.dart';
import 'package:completai/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class TestAuthRepository implements AuthRepository {
  AuthSession? session;
  Completer<AuthSession>? pending;
  Object? failure;
  @override
  Future<AuthSession?> restoreSession({bool forceRefresh = false}) async {
    if (failure != null) throw failure!;
    return session;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => pending!.future;
  @override
  Future<void> signOut() async {
    session = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TestAuthRepository repository;
  late ProviderContainer container;
  late AsyncNotifierProvider<AuthViewModel, AuthSession?> provider;

  setUp(() {
    repository = TestAuthRepository();
    final dependency = Provider<AuthRepository>((ref) => repository);
    provider = AsyncNotifierProvider<AuthViewModel, AuthSession?>(
      () => AuthViewModel(dependency),
    );
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  test('restaura sessão ausente e sai de loading', () async {
    expect(await container.read(provider.future), isNull);
    expect(container.read(provider).isLoading, isFalse);
  });

  test('login publica loading e a sessão retornada', () async {
    await container.read(provider.future);
    repository.pending = Completer<AuthSession>();
    final operation = container
        .read(provider.notifier)
        .signIn(email: 'a@b.com', password: 'secret');
    expect(container.read(provider).isLoading, isTrue);
    repository.pending!.complete(
      const AuthSession(uid: 'u1', email: 'a@b.com', role: AccountRole.client),
    );
    await operation;
    expect(container.read(provider).requireValue!.uid, 'u1');
    expect(container.read(provider).requireValue!.role, AccountRole.client);
  });

  test('falha de login fica disponível no AsyncError', () async {
    await container.read(provider.future);
    repository.pending = Completer<AuthSession>();
    final operation = container
        .read(provider.notifier)
        .signIn(email: 'a@b.com', password: 'wrong');
    repository.pending!.completeError(
      const AuthFailure('Credenciais inválidas.'),
    );
    await operation;
    expect(container.read(provider).error, isA<AuthFailure>());
    expect(container.read(provider).isLoading, isFalse);
  });

  test('falha na restauração não é convertida em logout', () async {
    repository.failure = const RoleConflictFailure('Papéis conflitantes.');
    await expectLater(
      container.read(provider.future),
      throwsA(isA<RoleConflictFailure>()),
    );
    expect(container.read(provider).hasError, isTrue);
  });

  test('logout limpa sessão e claim admin', () async {
    repository.session = const AuthSession(
      uid: 'admin',
      email: 'a@b.com',
      isAdmin: true,
    );
    await container.read(provider.future);
    await container.read(provider.notifier).signOut();
    expect(container.read(provider).requireValue, isNull);
  });
}
