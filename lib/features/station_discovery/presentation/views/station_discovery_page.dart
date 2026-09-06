// Home funcional do motorista: GPS, busca, filtros, swipe e atualização por gesto.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/station_brand_badge.dart';
import '../../../../core/widgets/station_logo.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../station_cover/presentation/providers/station_cover_providers.dart';
import '../../domain/models/station_summary.dart';
import '../../domain/station_opening_hours.dart';
import '../providers/station_discovery_providers.dart';
import '../widgets/station_fuel_selector.dart';
part 'station_discovery_widgets.dart';
part 'station_discovery_station_widgets.dart';

class StationDiscoveryPage extends ConsumerWidget {
  const StationDiscoveryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(stationDiscoveryViewModelProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(
        title: const Text('Meu combustível'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.account_circle),
            onPressed: () =>
                ref.read(sessionViewModelProvider.notifier).signOut(),
          ),
        ],
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LocationError(message: error.toString()),
        data: (state) => GestureDetector(
          onHorizontalDragEnd: (details) {
            final vm = ref.read(stationDiscoveryViewModelProvider.notifier);
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -200) vm.nextFuel();
            if (velocity > 200) vm.previousFuel();
          },
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(stationDiscoveryViewModelProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(state: state)),
                SliverToBoxAdapter(child: _Controls(state: state)),
                if (state.visibleStations.isNotEmpty)
                  SliverToBoxAdapter(child: _BestPriceBanner(state: state)),
                if (state.visibleStations.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('Nenhum posto encontrado com estes filtros.'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.separated(
                      itemCount: state.visibleStations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _StationCard(
                        station: state.visibleStations[index],
                        fuel: state.fuel,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
