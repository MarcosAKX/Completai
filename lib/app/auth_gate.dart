// Decide a rota inicial pela sessão: carregando, sem conta, perfil pendente ou logado.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_splash_mark.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import 'session_scope.dart';
import '../features/auth/presentation/views/login_page.dart';
import '../features/auth/presentation/views/role_selection_page.dart';
import '../features/auth/domain/models/auth_session.dart';
import '../features/admin/presentation/views/admin_page.dart';
import '../features/station_discovery/presentation/views/station_discovery_page.dart';
import '../features/station_panel/presentation/views/station_panel_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trocou de conta: descarta o que era da anterior. Sem isto, o painel
    // abria com o perfil do posto que acabou de sair, até alguém puxar para
    // atualizar — os providers não são autoDispose e guardam cache.
    ref.listen(sessionViewModelProvider, (previous, next) {
      final before = previous?.valueOrNull?.uid;
      final after = next.valueOrNull?.uid;
      if (before != after) resetUserScopedProviders(ref);
    });

    final session = ref.watch(sessionViewModelProvider);
    return session.when(
      loading: () => const _AuthGateSplash(),
      error: (_, _) => const LoginPage(),
      data: (session) {
        if (session == null) return const LoginPage();
        // Admin antes de `needsProfile`: a conta de admin não tem documento
        // em `users/` nem em `gas_stations/`, então sem isto ela cairia na
        // escolha de papel e ficaria presa lá — e escolher um papel a
        // tornaria cliente ou posto.
        if (session.isAdmin) return const AdminPage();
        if (session.needsProfile) return const RoleSelectionPage();
        if (session.role == AccountRole.client) {
          return const StationDiscoveryPage();
        }
        return const StationPanelPage();
      },
    );
  }
}

class _AuthGateSplash extends StatelessWidget {
  const _AuthGateSplash();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.primary,
    body: Center(child: AppSplashMark()),
  );
}
