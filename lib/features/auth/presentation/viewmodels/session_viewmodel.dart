import 'package:riverpod/riverpod.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class SessionViewModel extends AsyncNotifier<AuthSession?> {
  SessionViewModel(this._repositoryProvider);

  final ProviderListenable<AuthRepository> _repositoryProvider;

  AuthRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<AuthSession?> build() => _repository.restoreSession();

  void setSession(AuthSession session) {
    state = AsyncData(session);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.restoreSession(forceRefresh: true),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await _repository.signOut();
      return null;
    });
    state = result;
  }
}
