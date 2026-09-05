// Componentes visuais privados da home, separados para manter a View enxuta.
part of 'station_discovery_page.dart';

class _Header extends ConsumerWidget {
  const _Header({required this.state});
  final dynamic state;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Onde completar hoje?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _chooseCity(context, ref),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${state.city} · ${state.stations.length} postos encontrados',
                ),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: ref
              .read(stationDiscoveryViewModelProvider.notifier)
              .setSearch,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar posto ou bairro',
          ),
        ),
      ],
    ),
  );
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.state});
  final dynamic state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(stationDiscoveryViewModelProvider.notifier);
    return Column(
      children: [
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meu combustível',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              StationFuelSelector(
                selected: state.fuel as FuelType,
                onSelected: vm.selectFuel,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Só abertos'),
              Switch(value: state.onlyOpen, onChanged: vm.toggleOnlyOpen),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _filters(context, vm, state.minimumRating),
                icon: const Icon(Icons.tune),
                label: const Text('Filtros'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BestPriceBanner extends StatelessWidget {
  const _BestPriceBanner({required this.state});
  final dynamic state;
  @override
  Widget build(BuildContext context) {
    final stations = state.visibleStations as List<StationSummary>;
    final first = stations.first.priceFor(state.fuel as FuelType);
    final second = stations.length > 1
        ? stations[1].priceFor(state.fuel as FuelType)
        : null;
    final difference = first != null && second != null ? second - first : null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Icon(Icons.arrow_downward),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menor preço de ${_fuelName(state.fuel as FuelType)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  difference == null
                      ? 'Melhor preço encontrado na cidade'
                      : '${_price(difference)}/L abaixo do próximo preço',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
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
  Widget build(BuildContext context, WidgetRef ref) => Center(
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
