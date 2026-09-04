import 'package:riverpod/riverpod.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import 'session_viewmodel.dart';

class LoginViewModel extends AsyncNotifier<bool> {
  LoginViewModel(this._repositoryProvider, this._sessionProvider);

  final ProviderListenable<AuthRepository> _repositoryProvider;
  final ProviderListenable<SessionViewModel> _sessionProvider;

  AuthRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<bool> build() async => false;

  Future<void> signIn({required String email, required String password}) =>
      _run(() => _repository.signIn(email: email, password: password));

  Future<void> signInWithGoogle() => _run(_repository.signInWithGoogle);

  Future<void> _run(Future<AuthSession> Function() operation) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await operation();
      ref.read(_sessionProvider).setSession(session);
      return true;
    });
  }
}
