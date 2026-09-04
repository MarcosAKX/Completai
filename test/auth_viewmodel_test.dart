import 'dart:async';

import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/domain/models/station_registration.dart';
import 'package:completai/features/auth/domain/repositories/auth_repository.dart';
import 'package:completai/features/auth/presentation/viewmodels/client_registration_viewmodel.dart';
import 'package:completai/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:completai/features/auth/presentation/viewmodels/password_reset_viewmodel.dart';
import 'package:completai/features/auth/presentation/viewmodels/session_viewmodel.dart';
import 'package:completai/features/auth/presentation/viewmodels/station_registration_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class TestAuthRepository implements AuthRepository {
  AuthSession? session;
  Completer<AuthSession>? pendingLogin;
  Object? clientProfileFailure;
  int accountCreations = 0;
  int clientProfileAttempts = 0;
  int passwordResetRequests = 0;
  int stationProfileAttempts = 0;

  @override
  Future<AuthSession?> restoreSession({bool forceRefresh = false}) async =>
      session;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => pendingLogin!.future;

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String password,
  }) async {
    if (session != null && session!.email == email) return session!;
    accountCreations++;
    return session = AuthSession(uid: 'created', email: email);
  }

  @override
  Future<AuthSession> completeClientRegistration({
    required String name,
    required String phone,
  }) async {
    clientProfileAttempts++;
    final failure = clientProfileFailure;
    if (failure != null) throw failure;
    return session = AuthSession(
      uid: session!.uid,
      email: session!.email,
      role: AccountRole.client,
    );
  }

  @override
  Future<AuthSession> completeStationRegistration(
    StationRegistration registration,
  ) async {
    stationProfileAttempts++;
    return session = AuthSession(
      uid: session!.uid,
      email: session!.email,
      role: AccountRole.gasStation,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetRequests++;
  }

  @override
  Future<void> signOut() async => session = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TestAuthRepository repository;
  late Provider<AuthRepository> repositoryProvider;
  late AsyncNotifierProvider<SessionViewModel, AuthSession?> sessionProvider;
  late ProviderContainer container;

  setUp(() {
    repository = TestAuthRepository();
    repositoryProvider = Provider<AuthRepository>((ref) => repository);
    sessionProvider = AsyncNotifierProvider<SessionViewModel, AuthSession?>(
      () => SessionViewModel(repositoryProvider),
    );
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('login publica loading e atualiza a sessão compartilhada', () async {
    final loginProvider = AsyncNotifierProvider<LoginViewModel, bool>(
      () => LoginViewModel(repositoryProvider, sessionProvider.notifier),
    );
    await container.read(loginProvider.future);
    await container.read(sessionProvider.future);
    repository.pendingLogin = Completer<AuthSession>();

    final operation = container
        .read(loginProvider.notifier)
        .signIn(email: 'a@b.com', password: 'secret');

    expect(container.read(loginProvider).isLoading, isTrue);
    repository.pendingLogin!.complete(
      const AuthSession(uid: 'u1', email: 'a@b.com', role: AccountRole.client),
    );
    await operation;
    expect(container.read(loginProvider).requireValue, isTrue);
    expect(container.read(sessionProvider).requireValue!.uid, 'u1');
  });

  test('erro de login pertence somente ao LoginViewModel', () async {
    final loginProvider = AsyncNotifierProvider<LoginViewModel, bool>(
      () => LoginViewModel(repositoryProvider, sessionProvider.notifier),
    );
    await container.read(loginProvider.future);
    await container.read(sessionProvider.future);
    repository.pendingLogin = Completer<AuthSession>();

    final operation = container
        .read(loginProvider.notifier)
        .signIn(email: 'a@b.com', password: 'wrong');
    repository.pendingLogin!.completeError(
      const AuthFailure('Credenciais inválidas.'),
    );
    await operation;

    expect(container.read(loginProvider).error, isA<AuthFailure>());
    expect(container.read(sessionProvider).hasError, isFalse);
  });

  test('cadastro retoma perfil sem a View controlar conta criada', () async {
    final registrationProvider =
        AsyncNotifierProvider<ClientRegistrationViewModel, bool>(
          () => ClientRegistrationViewModel(
            repositoryProvider,
            sessionProvider.notifier,
          ),
        );
    await container.read(registrationProvider.future);
    await container.read(sessionProvider.future);
    expect(container.read(registrationProvider).requireValue, isFalse);
    repository.clientProfileFailure = const AuthFailure('Falha no perfil.');

    await container
        .read(registrationProvider.notifier)
        .register(
          email: 'novo@teste.com',
          password: 'secret',
          name: 'Novo Usuário',
          phone: '17999999999',
        );
    expect(container.read(registrationProvider).hasError, isTrue);

    repository.clientProfileFailure = null;
    await container
        .read(registrationProvider.notifier)
        .register(
          email: 'novo@teste.com',
          password: 'secret',
          name: 'Novo Usuário',
          phone: '17999999999',
        );

    expect(repository.accountCreations, 1);
    expect(repository.clientProfileAttempts, 2);
    expect(container.read(registrationProvider).requireValue, isTrue);
    expect(container.read(sessionProvider).requireValue, isNull);
  });

  test(
    'cadastro de posto coordena conta e perfil em um único comando',
    () async {
      final registrationProvider =
          AsyncNotifierProvider<StationRegistrationViewModel, bool>(
            () => StationRegistrationViewModel(
              repositoryProvider,
              sessionProvider.notifier,
            ),
          );
      await container.read(registrationProvider.future);
      await container.read(sessionProvider.future);
      expect(container.read(registrationProvider).requireValue, isFalse);

      await container
          .read(registrationProvider.notifier)
          .register(
            email: 'posto@teste.com',
            password: 'secret',
            registration: const StationRegistration(
              cnpj: '12345678000190',
              brandName: 'Posto Teste',
              phone: '17999999999',
              address: 'Rua Um, 10',
              neighborhood: 'Centro',
              city: 'Bebedouro',
            ),
          );

      expect(repository.accountCreations, 1);
      expect(repository.stationProfileAttempts, 1);
      expect(container.read(registrationProvider).requireValue, isTrue);
      expect(container.read(sessionProvider).requireValue, isNull);
    },
  );

  test('recuperação de senha mantém estado isolado da sessão', () async {
    final resetProvider = AsyncNotifierProvider<PasswordResetViewModel, bool>(
      () => PasswordResetViewModel(repositoryProvider),
    );
    await container.read(resetProvider.future);
    await container.read(sessionProvider.future);
    expect(container.read(resetProvider).requireValue, isFalse);

    await container.read(resetProvider.notifier).send('a@b.com');

    expect(repository.passwordResetRequests, 1);
    expect(container.read(resetProvider).requireValue, isTrue);
    expect(container.read(sessionProvider).requireValue, isNull);
  });

  test('logout pertence ao SessionViewModel e limpa a sessão', () async {
    repository.session = const AuthSession(uid: 'u1', email: 'a@b.com');
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signOut();

    expect(repository.session, isNull);
    expect(container.read(sessionProvider).requireValue, isNull);
  });
}