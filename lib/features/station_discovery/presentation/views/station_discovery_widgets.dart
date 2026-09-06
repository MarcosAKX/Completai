// Componentes visuais privados da home.
// A lógica permanece no ViewModel e nos Providers.
part of 'station_discovery_page.dart';

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.state});

  final dynamic state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      content: Text(
                        'As notificações serão adicionadas futuramente.',
                      ),
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
          ),
          const SizedBox(height: 32),
          const Text(
            'Olá!',
            style: TextStyle(
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
          InkWell(
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
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(stationDiscoveryViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.tune_rounded,
              title: 'Filtros',
              subtitle: 'Refine sua busca',
              onTap: () {
                final state = ref
                    .read(stationDiscoveryViewModelProvider)
                    .valueOrNull;

                if (state != null) {
                  _filters(context, vm, state.minimumRating);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: _QuickActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Meus abastecimentos',
              subtitle: 'Acompanhe seu histórico',
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: _QuickActionCard(
              icon: Icons.star_border_rounded,
              title: 'Postos favoritos',
              subtitle: 'Seus postos salvos',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 145),
          padding: const EdgeInsets.fromLTRB(10, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E9F4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 25),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 9),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSearch extends ConsumerWidget {
  const _HomeSearch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: TextField(
        onChanged: ref
            .read(stationDiscoveryViewModelProvider.notifier)
            .setSearch,
        decoration: InputDecoration(
          hintText: 'Buscar posto ou bairro',
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Colors.white,
          border: _searchBorder(),
          enabledBorder: _searchBorder(),
          focusedBorder: _searchBorder(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

OutlineInputBorder _searchBorder({
  Color color = const Color(0xFFE4E9F4),
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.state});

  final dynamic state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(stationDiscoveryViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E9F4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.local_gas_station_outlined,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Meu combustível',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StationFuelSelector(
              selected: state.fuel as FuelType,
              onSelected: vm.selectFuel,
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mostrar somente postos abertos',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Switch(value: state.onlyOpen, onChanged: vm.toggleOnlyOpen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StationsTitle extends StatelessWidget {
  const _StationsTitle({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Postos próximos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '$amount encontrados',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            FilledButton(
              onPressed: () => _chooseCity(context, ref),
              child: const Text('Escolher cidade manualmente'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _chooseCity(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();

  final city = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Escolher cidade em SP'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Ex.: Bebedouro'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Buscar'),
        ),
      ],
    ),
  );

  controller.dispose();

  if (city != null && city.trim().isNotEmpty) {
    await ref.read(stationDiscoveryViewModelProvider.notifier).selectCity(city);
  }
}

Future<void> _filters(BuildContext context, dynamic vm, double current) async {
  final value = await showModalBottomSheet<double>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Avaliação mínima')),
          for (final rating in [0.0, 3.0, 4.0, 4.5])
            ListTile(
              leading: Icon(
                rating == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(rating == 0 ? 'Todas' : '$rating ou mais'),
              onTap: () => Navigator.pop(context, rating),
            ),
        ],
      ),
    ),
  );

  if (value != null) {
    vm.setMinimumRating(value);
  }
}
