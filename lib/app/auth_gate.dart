// Decide a rota inicial pela sessão: carregando, sem conta, perfil pendente ou logado.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_splash_mark.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/views/login_page.dart';
import '../features/auth/presentation/views/role_selection_page.dart';
import '../features/auth/domain/models/auth_session.dart';
import '../features/station_discovery/presentation/views/station_discovery_page.dart';
import 'home_placeholder.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionViewModelProvider);
    return session.when(
      loading: () => const _AuthGateSplash(),
      error: (_, _) => const LoginPage(),
      data: (session) {
        if (session == null) return const LoginPage();
        if (session.needsProfile) return const RoleSelectionPage();
        if (session.role == AccountRole.client) {
          return const StationDiscoveryPage();
        }
        return HomePlaceholder(session: session);
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
