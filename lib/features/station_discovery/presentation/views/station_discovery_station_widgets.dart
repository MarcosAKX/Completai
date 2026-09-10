// Cards e painel do posto, separados da composição principal.
part of 'station_discovery_page.dart';

class _StationCard extends ConsumerWidget {
  const _StationCard({required this.station, required this.fuel});

  final StationSummary station;
  final FuelType fuel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = isStationOpen(DateTime.now(), station.openingHours);

    final coverBytes = ref
        .watch(stationCoverProvider(station.uid))
        .valueOrNull
        ?.bytes;

    return Card(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: AppColors.primary.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.stationCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StationDetailsPage(
              stationUid: station.uid,
              distanceKm: station.distanceKm,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              //
              // Informações principais do posto.
              //
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //
                  // Foto / imagem do posto.
                  //
                  StationLogo(
                    stationName: station.name,
                    imageBytes: coverBytes,
                    size: 72,
                  ),

                  const SizedBox(width: 14),

                  //
                  // Nome, bandeira, distância e funcionamento.
                  //
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //
                        // Nome agora possui uma linha própria.
                        //
                        Text(
                          station.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        //
                        // Bandeira seguida da distância.
                        //
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StationBrandBadge(brand: station.brand),

                            if (station.distanceKm != null)
                              Text(
                                '${station.distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        //
                        // Situação do posto.
                        //
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: Text(open ? 'Aberto agora' : 'Fechado'),
                            avatar: Icon(
                              Icons.circle,
                              size: 9,
                              color: open ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24, color: AppColors.outline),

              //
              // Preços dos combustíveis.
              //
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
                                : AppColors.stationPriceSurface,
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

              //
              // Avaliação e atualização dos preços.
              //
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.accent, size: 17),

                  Flexible(
                    child: Text(
                      ' ${station.averageRating.toStringAsFixed(1)}'
                      ' · ${station.reviewCount} avaliações',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

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

String _fuelName(FuelType value) => switch (value) {
  FuelType.gasoline => 'Gasolina',
  FuelType.ethanol => 'Etanol',
  FuelType.diesel => 'Diesel',
};

String _price(double? value) => value == null
    ? '—'
    : 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String _updated(DateTime? date) {
  if (date == null) {
    return 'Sem atualização';
  }

  final days = DateTime.now().difference(date).inDays;

  return days == 0 ? 'Atualizado hoje' : 'Atualizado há $days d';
}
