// Orquestra serviços e mantém o único cache de perfil,
// restrito ao UID da sessão.
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/station_registration.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_profile_service.dart';
import '../services/firebase_auth_service.dart';
import 'auth_failure_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._profiles);

  final FirebaseAuthService _auth;
  final AuthProfileService _profiles;

  AuthSession? _cachedSession;

  // uid da conta criada nesta passagem de cadastro (não reaproveitada).
  // Serve para `discardIncompleteAccount` só apagar o que ela mesma criou.
  String? _accountCreatedThisFlow;

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stack) {
      _cachedSession = null;
      final failure = mapAuthFailure(error);
      // Loga a causa real — a UI só mostra a mensagem tratada. Aparece no
      // console do `flutter run` e no DevTools.
      developer.log(
        'operação de auth falhou',
        name: 'auth',
        error: error,
        stackTrace: stack,
      );
      Error.throwWithStackTrace(failure, stack);
    }
  }

  Future<AuthSession> _session(User user, {bool forceRefresh = false}) async {
    final cached = _cachedSession;

    if (!forceRefresh && cached?.uid == user.uid) {
      return cached!;
    }

    _cachedSession = null;

    // Perfil do Firestore e claim de administrador podem
    // ser consultados em paralelo.
    final results = await Future.wait([
      _profiles.readProfile(user.uid),
      _auth.isAdmin(forceRefresh: forceRefresh),
    ]);

    final profile = results[0] as AuthProfileData;
    final admin = results[1] as bool;

    // Garante que o usuário não saiu enquanto os dados
    // da sessão estavam sendo carregados.
    if (_auth.currentUser?.uid != user.uid) {
      throw const UnauthenticatedException();
    }

    return _cachedSession = AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      name: profile.name,
      role: profile.role,
      isAdmin: admin,
    );
  }

  @override
  Future<AuthSession?> restoreSession({bool forceRefresh = false}) =>
      _guard(() async {
        final user = _auth.currentUser;

        if (user == null) {
          _cachedSession = null;
          return null;
        }

        return _session(user, forceRefresh: forceRefresh);
      });

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    _cachedSession = null;

    final user = await _auth.signIn(email: email, password: password);

    return _session(user);
  });

  @override
  Future<AuthSession> signInWithGoogle() => _guard(() async {
    _cachedSession = null;

    return _session(await _auth.signInWithGoogle());
  });

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String password,
  }) => _guard(() async {
    _cachedSession = null;

    final existing = _auth.currentUser;

    if (existing != null &&
        existing.email?.trim().toLowerCase() == email.trim().toLowerCase()) {
      _accountCreatedThisFlow = null;
      return _session(existing, forceRefresh: true);
    }

    if (existing != null) {
      throw const ValidationException(
        'Saia da conta atual antes de cadastrar outro e-mail.',
      );
    }

    final user = await _auth.createAccount(email: email, password: password);
    _accountCreatedThisFlow = user.uid;

    return _session(user);
  });

  User _requireUser() {
    return _auth.currentUser ?? (throw const UnauthenticatedException());
  }

  @override
  Future<AuthSession> completeClientRegistration({
    required String name,
    required String phone,
  }) => _guard(() async {
    final user = _requireUser();

    await _profiles.createClient(
      uid: user.uid,
      email: user.email ?? '',
      name: name,
      phone: phone,
    );

    _accountCreatedThisFlow = null;
    // Atualiza a sessão para incluir imediatamente o nome criado.
    return _session(user, forceRefresh: true);
  });

  @override
  Future<AuthSession> completeStationRegistration(
    StationRegistration registration,
  ) => _guard(() async {
    final user = _requireUser();

    await _profiles.createStation(
      uid: user.uid,
      email: user.email ?? '',
      registration: registration,
    );

    _accountCreatedThisFlow = null;
    return _session(user, forceRefresh: true);
  });

  @override
  Future<void> discardIncompleteAccount() => _guard(() async {
    final user = _auth.currentUser;
    if (user != null && user.uid == _accountCreatedThisFlow) {
      await _auth.deleteCurrentAccount();
    }
    _accountCreatedThisFlow = null;
    _cachedSession = null;
  });

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email));

  @override
  Future<void> signOut() => _guard(() async {
    _cachedSession = null;
    await _auth.signOut();
  });
}
