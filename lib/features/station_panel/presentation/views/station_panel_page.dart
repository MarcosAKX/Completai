// Área administrativa do dono do posto: prévia, preços e (em breve) o resto.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/station_panel_providers.dart';
import '../widgets/station_panel_placeholder_tab.dart';
import 'station_hours_tab.dart';
import 'station_info_tab.dart';
import 'station_prices_tab.dart';
import 'station_profile_page.dart';

class StationPanelPage extends ConsumerStatefulWidget {
  const StationPanelPage({super.key});

  @override
  ConsumerState<StationPanelPage> createState() => _StationPanelPageState();
}

class _StationPanelPageState extends ConsumerState<StationPanelPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stationPanelViewModelProvider);
    final name = state.valueOrNull?.name;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name == null || name.isEmpty ? 'CompletAI' : name,
              style: AppTextStyles.label,
            ),
            Text(
              'Área administrativa',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil do posto',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: state.hasValue
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StationProfilePage(),
                    ),
                  )
                : null,
          ),
        ],
      ),
      body: switch (state) {
        AsyncValue(hasValue: true) => IndexedStack(
          index: _tab,
          children: const [
            StationPricesTab(),
            StationInfoTab(),
            StationHoursTab(),
            StationPanelPlaceholderTab(
              icon: Icons.reviews_outlined,
              title: 'Avaliações',
              message:
                  'As avaliações dos clientes aparecerão aqui quando começarem a avaliar.',
            ),
          ],
        ),
        AsyncError(:final error) => _PanelError(message: error.toString()),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: state.hasValue
          ? NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (index) => setState(() => _tab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.local_gas_station_outlined),
                  selectedIcon: Icon(Icons.local_gas_station),
                  label: 'Preços',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  label: 'Informações',
                ),
                NavigationDestination(
                  icon: Icon(Icons.schedule_outlined),
                  label: 'Horários',
                ),
                NavigationDestination(
                  icon: Icon(Icons.reviews_outlined),
                  label: 'Avaliações',
                ),
              ],
            )
          : null,
    );
  }
}

class _PanelError extends ConsumerWidget {
  const _PanelError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Tentar novamente',
            onPressed: () =>
                ref.read(stationPanelViewModelProvider.notifier).reload(),
          ),
        ],
      ),
    ),
  );
}
