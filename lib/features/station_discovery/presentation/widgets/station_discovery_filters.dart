// Filtros, ordenação e título da listagem de postos.
part of '../views/station_discovery_page.dart';

class _StationsTitle extends ConsumerWidget {
  const _StationsTitle({required this.amount, required this.sortMode});

  final int amount;
  final StationSortMode sortMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Postos próximos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),

              OutlinedButton.icon(
                onPressed: () => _sortStations(context, ref, sortMode),
                icon: const Icon(Icons.swap_vert_rounded, size: 18),
                label: const Text('Ordenar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            '$amount encontrados · ${_sortLabel(sortMode)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _filters(
  BuildContext context,
  WidgetRef ref,
  StationDiscoveryState current,
) async {
  var distance = current.maximumDistanceKm;
  var rating = current.minimumRating;
  var onlyOpen = current.onlyOpen;

  final apply = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 24),

                const _FilterTitle(
                  icon: Icons.near_me_outlined,
                  text: 'Distância máxima',
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <double?>[null, 2, 5, 10].map((value) {
                    return ChoiceChip(
                      label: Text(
                        value == null ? 'Qualquer' : '${value.toInt()} km',
                      ),
                      selected: distance == value,
                      onSelected: (_) {
                        setState(() => distance = value);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                const _FilterTitle(
                  icon: Icons.star_outline_rounded,
                  text: 'Avaliação mínima',
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <double>[0, 3, 4, 4.5].map((value) {
                    return ChoiceChip(
                      label: Text(
                        value == 0 ? 'Todas' : '${value.toStringAsFixed(1)}+',
                      ),
                      selected: rating == value,
                      onSelected: (_) {
                        setState(() => rating = value);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Somente postos abertos',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Ocultar postos que estão fechados agora',
                  ),
                  value: onlyOpen,
                  onChanged: (value) {
                    setState(() => onlyOpen = value);
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            distance = null;
                            rating = 0;
                            onlyOpen = false;
                          });
                        },
                        child: const Text('Limpar filtros'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (apply != true) {
    return;
  }

  final vm = ref.read(stationDiscoveryViewModelProvider.notifier);

  vm
    ..setMinimumRating(rating)
    ..setMaximumDistance(distance)
    ..toggleOnlyOpen(onlyOpen);
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

Future<void> _sortStations(
  BuildContext context,
  WidgetRef ref,
  StationSortMode current,
) async {
  final selected = await showModalBottomSheet<StationSortMode>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Ordenar por',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),

          for (final mode in StationSortMode.values)
            RadioListTile<StationSortMode>(
              value: mode,
              groupValue: current,
              title: Text(_sortLabel(mode)),
              secondary: Icon(_sortIcon(mode)),
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
            ),

          const SizedBox(height: 12),
        ],
      ),
    ),
  );

  if (selected != null) {
    ref.read(stationDiscoveryViewModelProvider.notifier).setSortMode(selected);
  }
}

String _sortLabel(StationSortMode mode) {
  return switch (mode) {
    StationSortMode.lowestPrice => 'Menor preço',
    StationSortMode.nearest => 'Mais próximo',
    StationSortMode.bestRating => 'Melhor avaliação',
  };
}

IconData _sortIcon(StationSortMode mode) {
  return switch (mode) {
    StationSortMode.lowestPrice => Icons.attach_money_rounded,
    StationSortMode.nearest => Icons.near_me_outlined,
    StationSortMode.bestRating => Icons.star_outline_rounded,
  };
}
