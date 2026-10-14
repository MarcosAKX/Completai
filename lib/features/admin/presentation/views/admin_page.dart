// Área do administrador: fila de aprovação, postos listados e denúncias.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/admin_providers.dart';
import 'admin_listed_tab.dart';
import 'admin_pending_tab.dart';
import 'admin_reports_tab.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Contadores no rótulo das abas: o admin precisa saber que tem fila sem
    // abrir cada uma.
    final pendingCount =
        ref.watch(adminStationsViewModelProvider).valueOrNull?.pendingCount ??
        0;
    final reportCount =
        ref.watch(adminReportsViewModelProvider).valueOrNull?.pendingCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CompletAI', style: AppTextStyles.label),
            Text(
              'Administração',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(sessionViewModelProvider.notifier).signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          AdminPendingTab(),
          AdminListedTab(),
          AdminReportsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          NavigationDestination(
            icon: _Badge(count: pendingCount, child: const Icon(Icons.pending_actions_outlined)),
            selectedIcon: _Badge(count: pendingCount, child: const Icon(Icons.pending_actions)),
            label: 'Pendentes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station),
            label: 'Postos listados',
          ),
          NavigationDestination(
            icon: _Badge(count: reportCount, child: const Icon(Icons.flag_outlined)),
            selectedIcon: _Badge(count: reportCount, child: const Icon(Icons.flag)),
            label: 'Denúncias',
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => count == 0
      ? child
      : Badge.count(count: count, child: child);
}
