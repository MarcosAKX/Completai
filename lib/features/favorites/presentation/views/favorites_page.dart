// Lista privada de favoritos; View delega operações aos ViewModels.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../station_details/domain/models/station_details.dart';
import '../../../station_details/presentation/providers/station_details_providers.dart';
import '../../../station_details/presentation/views/station_details_page.dart';
import '../providers/favorites_providers.dart';
import '../widgets/favorite_station_card.dart';
import '../widgets/favorites_empty.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    String uid,
    StationDetails station,
  ) async {
    final vm = ref.read(favoritesViewModelProvider(uid).notifier);
    if (!await vm.remove(station) || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${station.name} removido dos favoritos.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            if (!context.mounted) return;
            final ok = await vm.undo(station);
            if (context.mounted && !ok) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Não foi possível desfazer. Tente novamente.'),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    String uid,
    StationDetails station,
  ) async {
    // Força leitura para que o coração reflita remoções feitas nesta lista.
    final vm = ref.read(stationDetailsViewModelProvider(station.uid).notifier);
    if (ref.read(stationDetailsViewModelProvider(station.uid)).hasValue) {
      await vm.refresh();
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StationDetailsPage(stationUid: station.uid),
      ),
    );
    if (context.mounted) {
      await ref.read(favoritesViewModelProvider(uid).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(sessionViewModelProvider).valueOrNull?.uid;
    final provider = uid == null ? null : favoritesViewModelProvider(uid);
    final state = provider == null ? null : ref.watch(provider);
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Meus favoritos'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
      ),
      body: state == null
          ? const Center(child: Text('Entre na conta para ver seus favoritos.'))
          : state.when(
              skipLoadingOnRefresh: true,
              skipError: state.hasValue,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(error.toString()),
                    AppButton(
                      label: 'Tentar novamente',
                      onPressed: () => ref.invalidate(provider!),
                    ),
                  ],
                ),
              ),
              data: (data) {
                final vm = ref.read(provider!.notifier);
                final visible = data.visible;
                return RefreshIndicator(
                  onRefresh: () async {
                    await vm.refresh();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: visible.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Seus postos salvos, em um só lugar.',
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              initialValue: data.search,
                              onChanged: vm.search,
                              enabled: !state.isLoading,
                              decoration: const InputDecoration(
                                hintText: 'Buscar nos favoritos',
                                prefixIcon: Icon(Icons.search),
                                filled: true,
                                fillColor: AppColors.surface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              '${data.stations.length} postos ${data.hasMore ? 'carregados' : 'salvos'}',
                              style: AppTextStyles.label,
                            ),
                            if (data.hasMore)
                              const Text(
                                'A busca considera os favoritos carregados.',
                                style: AppTextStyles.caption,
                              ),
                            if (state.isLoading)
                              const LinearProgressIndicator(),
                            if (state.hasError)
                              Text(
                                state.error.toString(),
                                style: const TextStyle(color: AppColors.error),
                              ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        );
                      }
                      if (index <= visible.length) {
                        final station = visible[index - 1];
                        return FavoriteStationCard(
                          key: ValueKey(station.uid),
                          station: station,
                          onOpen: state.isLoading
                              ? null
                              : () => _open(context, ref, uid!, station),
                          onRemove: state.isLoading
                              ? null
                              : () => _remove(context, ref, uid!, station),
                        );
                      }
                      return Column(
                        children: [
                          if (visible.isEmpty)
                            FavoritesEmpty(
                              searching: data.search.trim().isNotEmpty,
                              hasMore: data.hasMore,
                              onExplore: () => Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              ),
                            ),
                          if (data.hasMore)
                            AppButton(
                              label: 'Carregar mais',
                              isLoading: state.isLoading,
                              onPressed: vm.loadMore,
                            ),
                          if (visible.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: Text(
                                'Toque em um posto para ver os detalhes.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
