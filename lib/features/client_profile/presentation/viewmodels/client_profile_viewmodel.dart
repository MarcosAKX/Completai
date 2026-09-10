// Estado do perfil e operações assíncronas; sem dependência de widgets.
import 'package:riverpod/riverpod.dart';
import '../../domain/models/client_profile.dart';
import '../../domain/repositories/client_profile_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/viewmodels/session_viewmodel.dart';

class ClientProfileViewModel
    extends AutoDisposeFamilyAsyncNotifier<ClientProfile, String> {
  ClientProfileViewModel(
    this.repositoryProvider,
    this.authProvider,
    this.sessionProvider,
  );
  final ProviderListenable<ClientProfileRepository> repositoryProvider;
  final ProviderListenable<AuthRepository> authProvider;
  final ProviderListenable<SessionViewModel> sessionProvider;
  late String _uid;

  @override
  Future<ClientProfile> build(String arg) {
    _uid = arg;
    return ref.read(repositoryProvider).load(arg);
  }

  Future<bool> save({required String name, required String phone}) async {
    if (state.isLoading) return false;
    final previous = state;
    state = const AsyncValue<ClientProfile>.loading().copyWithPrevious(
      previous,
    );
    final result = await AsyncValue.guard(() async {
      final profile = await ref
          .read(repositoryProvider)
          .save(_uid, name: name, phone: phone);
      final session = await ref
          .read(authProvider)
          .restoreSession(forceRefresh: true);
      if (session != null && session.uid == _uid) {
        ref.read(sessionProvider).setSession(session);
      }
      return profile;
    });
    state = result.hasError ? result.copyWithPrevious(previous) : result;
    return !result.hasError;
  }
}
