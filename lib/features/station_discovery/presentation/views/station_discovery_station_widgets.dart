// Cards e painel do posto, separados da composição principal.
part of 'station_discovery_page.dart';

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.fuel});
  final StationSummary station;
  final FuelType fuel;
  @override
  Widget build(BuildContext context) {
    final open = isStationOpen(DateTime.now(), station.todayHours);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => _StationPanel(station: station),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(station.name.substring(0, 1).toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${station.neighborhood}${station.distanceKm == null ? '' : ' · ${station.distanceKm!.toStringAsFixed(1)} km'}',
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(open ? 'Aberto agora' : 'Fechado'),
                    avatar: Icon(
                      Icons.circle,
                      size: 9,
                      color: open ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: FuelType.values
                    .map(
                      (item) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: item == fuel
                                ? AppColors.primaryLight
                                : AppColors.screenBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fuelName(item).toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                _price(station.priceFor(item)),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: item == fuel
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.accent, size: 17),
                  Text(
                    ' ${station.averageRating.toStringAsFixed(1)} · ${station.reviewCount} avaliações',
                  ),
                  const Spacer(),
                  Text(
                    _updated(station.pricesUpdatedAt),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationPanel extends StatelessWidget {
  const _StationPanel({required this.station});
  final StationSummary station;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(station.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${station.neighborhood}, ${station.city}'),
          const SizedBox(height: 16),
          Text(
            '${station.averageRating.toStringAsFixed(1)} de avaliação · ${station.reviewCount} avaliações',
          ),
          const SizedBox(height: 20),
          const Text(
            'O perfil completo do posto será ampliado com serviços, horários e avaliações.',
          ),
        ],
      ),
    ),
  );
}

String _fuelName(FuelType value) => switch (value) {
  FuelType.gasoline => 'Gasolina',
  FuelType.ethanol => 'Etanol',
  FuelType.diesel => 'Diesel',
};
String _price(double? value) => value == null
    ? '—'
    : 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
String _updated(DateTime? date) {
  if (date == null) return 'Sem atualização';
  final days = DateTime.now().difference(date).inDays;
  return days == 0 ? 'Atualizado hoje' : 'Atualizado há $days d';
}
