// Cabeçalho da Home, seleção de cidade e erro de localização.
part of '../views/station_discovery_page.dart';

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.state});

  final StationDiscoveryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref
        .watch(sessionViewModelProvider)
        .valueOrNull
        ?.firstName;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderTopBar(ref: ref),

          const SizedBox(height: 32),

          Text(
            firstName == null ? 'Olá!' : 'Olá, $firstName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Tudo pronto para o seu próximo abastecimento.',
            style: TextStyle(color: Colors.white, fontSize: 18, height: 1.35),
          ),

          const SizedBox(height: 24),

          _CitySelector(state: state, ref: ref),
        ],
      ),
    );
  }
}

class _HeaderTopBar extends StatelessWidget {
  const _HeaderTopBar({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Completai!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        IconButton(
          tooltip: 'Notificações',
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('As notificações serão adicionadas futuramente.'),
              ),
            );
          },
        ),

        const SizedBox(width: 4),

        PopupMenuButton<String>(
          tooltip: 'Perfil',
          onSelected: (value) {
            if (value == 'logout') {
              ref.read(sessionViewModelProvider.notifier).signOut();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 10),
                  Text('Sair'),
                ],
              ),
            ),
          ],
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _CitySelector extends StatelessWidget {
  const _CitySelector({required this.state, required this.ref});

  final StationDiscoveryState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _chooseCity(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.white),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                '${state.city} · ${state.stations.length} postos',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _LocationError extends ConsumerWidget {
  const _LocationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 52,
              color: AppColors.primary,
            ),

            const SizedBox(height: 16),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: () => _chooseCity(context, ref),
              icon: const Icon(Icons.location_city_outlined),
              label: const Text('Escolher cidade'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _chooseCity(BuildContext context, WidgetRef ref) async {
  final vm = ref.read(stationDiscoveryViewModelProvider.notifier);

  List<String> cities;

  try {
    cities = await vm.loadAvailableCities();
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível carregar as cidades disponíveis.'),
      ),
    );

    return;
  }

  if (!context.mounted) {
    return;
  }

  final selectedCity = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escolher cidade',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 6),

              const Text(
                'Cidades com postos cadastrados',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),

              const SizedBox(height: 16),

              if (cities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nenhuma cidade com postos cadastrados foi encontrada.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...cities.map((city) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.location_on_outlined),
                    ),
                    title: Text(
                      city,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(sheetContext, city);
                    },
                  );
                }),
            ],
          ),
        ),
      );
    },
  );

  if (selectedCity == null) {
    return;
  }

  await vm.selectCity(selectedCity);
}
