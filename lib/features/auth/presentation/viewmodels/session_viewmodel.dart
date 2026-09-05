import 'package:riverpod/riverpod.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class SessionViewModel extends AsyncNotifier<AuthSession?> {
  SessionViewModel(
    this._repositoryProvider, {
    this.minimumLoadingDuration = Duration.zero,
  });

  final ProviderListenable<AuthRepository> _repositoryProvider;
  final Duration minimumLoadingDuration;

  AuthRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<AuthSession?> build() async {
    final stopwatch = Stopwatch()..start();
    final session = await _repository.restoreSession();
    final remaining = minimumLoadingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    return session;
  }

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
