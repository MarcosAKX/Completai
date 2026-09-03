import 'package:riverpod/riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import 'session_viewmodel.dart';

class ClientRegistrationViewModel extends AsyncNotifier<bool> {
  ClientRegistrationViewModel(this._repositoryProvider, this._sessionProvider);

  final ProviderListenable<AuthRepository> _repositoryProvider;
  final ProviderListenable<SessionViewModel> _sessionProvider;

  AuthRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<bool> build() async => false;

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.createAccount(email: email, password: password);
      final session = await _repository.completeClientRegistration(
        name: name,
        phone: phone,
      );
      ref.read(_sessionProvider).setSession(session);
      return true;
    });
  }
}
