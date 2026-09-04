import 'package:riverpod/riverpod.dart';

import '../../domain/repositories/auth_repository.dart';

class PasswordResetViewModel extends AsyncNotifier<bool> {
  PasswordResetViewModel(this._repositoryProvider);

  final ProviderListenable<AuthRepository> _repositoryProvider;

  AuthRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<bool> build() async => false;

  Future<void> send(String email) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.sendPasswordResetEmail(email);
      return true;
    });
  }
}
