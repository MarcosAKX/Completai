// Coordena comandos em AsyncValue, dependendo apenas do contrato do Repository.
import 'package:riverpod/riverpod.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/station_registration.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthViewModel extends AsyncNotifier<AuthSession?> {
  AuthViewModel(this._repositoryProvider);
  final ProviderListenable<AuthRepository> _repositoryProvider;
  bool _busy = false;
  bool _disposed = false;

  AuthRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<AuthSession?> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final result = await AsyncValue.guard(() => _repository.restoreSession());
    return result.requireValue;
  }

  Future<void> _run(Future<AuthSession?> Function() operation) async {
    if (_busy || state.isLoading) return;
    _busy = true;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(operation);
    if (!_disposed) state = result;
    _busy = false;
  }

  Future<void> signIn({required String email, required String password}) =>
      _run(() => _repository.signIn(email: email, password: password));
  Future<void> signInWithGoogle() => _run(_repository.signInWithGoogle);
  Future<void> createAccount({
    required String email,
    required String password,
  }) => _run(() => _repository.createAccount(email: email, password: password));
  Future<void> completeClientRegistration({required String name}) =>
      _run(() => _repository.completeClientRegistration(name: name));
  Future<void> completeStationRegistration(StationRegistration registration) =>
      _run(() => _repository.completeStationRegistration(registration));
  Future<void> refreshSession() =>
      _run(() => _repository.restoreSession(forceRefresh: true));
  Future<void> sendPasswordResetEmail(String email) => _run(() async {
    await _repository.sendPasswordResetEmail(email);
    return _repository.restoreSession();
  });
  Future<void> signOut() => _run(() async {
    await _repository.signOut();
    return null;
  });
}
