// MOCKUP navegável de descoberta; usa somente dados locais e pode ser removido.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/fuel_prototype_station.dart';
import '../providers/fuel_discovery_prototype_provider.dart';
import '../viewmodels/fuel_discovery_prototype_viewmodel.dart';
import '../widgets/fuel_prototype_widgets.dart';

class FuelDiscoveryPrototypePage extends ConsumerWidget {
  const FuelDiscoveryPrototypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fuelDiscoveryPrototypeProvider);
    final notifier = ref.read(fuelDiscoveryPrototypeProvider.notifier);
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FF),
      appBar: AppBar(
        title: const Text('Meu combustível'),
        actions: [
          GestureDetector(
            onLongPress: () => _showStateMenu(context, notifier),
            child: const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: CircleAvatar(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                child: Text('U'),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 150) notifier.nextFuel();
          if (velocity < -150) notifier.previousFuel();
        },
        child: Column(
          children: [
            PrototypeDiscoveryHeader(
              state: state,
              onCityTap: () => _showCities(context, notifier),
              onSearch: notifier.search,
            ),
            PrototypeFuelSelector(
              selected: state.fuel,
              onSelected: notifier.selectFuel,
            ),
            Expanded(
              child: state.screenState == PrototypeScreenState.loaded
                  ? RefreshIndicator(
                      onRefresh: notifier.refresh,
                      child: PrototypeLoadedList(
                        state: state,
                        onOnlyOpen: notifier.toggleOnlyOpen,
                        onStationTap: (station) =>
                            _showStationPanel(context, station, state.fuel),
                      ),
                    )
                  : SingleChildScrollView(
                      child: PrototypeSpecialState(
                        state: state.screenState,
                        onChooseCity: () => _showCities(context, notifier),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCities(
    BuildContext context,
    FuelDiscoveryPrototypeViewModel notifier,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Bebedouro', 'Campinas', 'Ribeirão Preto']
            .map(
              (city) => ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text('$city, SP'),
                onTap: () {
                  notifier.selectCity(city);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    ),
  );

  Future<void> _showStateMenu(
    BuildContext context,
    FuelDiscoveryPrototypeViewModel notifier,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: PrototypeScreenState.values
            .map(
              (value) => ListTile(
                title: Text('Simular: ${value.name}'),
                onTap: () {
                  notifier.simulate(value);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    ),
  );

  Future<void> _showStationPanel(
    BuildContext context,
    FuelPrototypeStation station,
    PrototypeFuel fuel,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Painel do posto', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.sm),
            Text(station.name, style: AppTextStyles.title),
            Text(
              station.neighborhood,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '${prototypeFuelLabel(fuel)} · R\$ ${station.priceFor(fuel).toStringAsFixed(2).replaceAll('.', ',')}',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
