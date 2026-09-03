// Orquestra serviços e mantém o único cache de perfil, restrito ao UID da sessão.
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

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stack) {
      _cachedSession = null;
      Error.throwWithStackTrace(mapAuthFailure(error), stack);
    }
  }

  Future<AuthSession> _session(User user, {bool forceRefresh = false}) async {
    final cached = _cachedSession;
    if (!forceRefresh && cached?.uid == user.uid) return cached!;
    _cachedSession = null;
    final role = await _profiles.readRole(user.uid);
    final admin = await _auth.isAdmin(forceRefresh: forceRefresh);
    if (_auth.currentUser?.uid != user.uid) {
      throw const UnauthenticatedException();
    }
    return _cachedSession = AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
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
    return _session(await _auth.signIn(email: email, password: password));
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
    return _session(
      await _auth.createAccount(email: email, password: password),
    );
  });

  User _requireUser() =>
      _auth.currentUser ?? (throw const UnauthenticatedException());

  @override
  Future<AuthSession> completeClientRegistration({required String name}) =>
      _guard(() async {
        final user = _requireUser();
        await _profiles.createClient(
          uid: user.uid,
          email: user.email ?? '',
          name: name,
        );
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
    return _session(user, forceRefresh: true);
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
