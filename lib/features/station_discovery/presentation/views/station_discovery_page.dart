// Home do motorista: GPS, busca, filtros, swipe e atualização por gesto.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/station_brand_badge.dart';
import '../../../../core/widgets/station_logo.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../station_cover/presentation/providers/station_cover_providers.dart';
import '../../../station_details/presentation/views/station_details_page.dart';
import '../../domain/models/station_summary.dart';
import '../../domain/station_opening_hours.dart';
import '../../domain/station_discovery_scope.dart';
import '../providers/station_discovery_providers.dart';
import '../viewmodels/station_discovery_viewmodel.dart';
import '../widgets/station_fuel_selector.dart';

part 'station_discovery_station_widgets.dart';
part '../widgets/station_discovery_header.dart';
part '../widgets/station_discovery_controls.dart';
part '../widgets/station_discovery_filters.dart';

class StationDiscoveryPage extends ConsumerWidget {
  const StationDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(stationDiscoveryViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: discovery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LocationError(message: error.toString()),
        data: (state) => _DiscoveryContent(state: state, ref: ref),
      ),
    );
  }
}

class _DiscoveryContent extends StatelessWidget {
  const _DiscoveryContent({required this.state, required this.ref});

  final StationDiscoveryState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(stationDiscoveryViewModelProvider.notifier);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;

        if (velocity < -200) {
          vm.nextFuel();
        }

        if (velocity > 200) {
          vm.previousFuel();
        }
      },
      child: RefreshIndicator(
        onRefresh: vm.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _HomeHeader(state: state)),

            const SliverToBoxAdapter(child: _QuickActions()),

            const SliverToBoxAdapter(child: _HomeSearch()),

            SliverToBoxAdapter(child: _Controls(state: state)),

            if (state.visibleStations.isNotEmpty)
              SliverToBoxAdapter(
                child: _StationsTitle(
                  amount: state.visibleStations.length,
                  sortMode: state.sortMode,
                ),
              ),

            if (state.visibleStations.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhum posto encontrado com estes filtros.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.separated(
                  itemCount: state.visibleStations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    return _StationCard(
                      station: state.visibleStations[index],
                      fuel: state.fuel,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
