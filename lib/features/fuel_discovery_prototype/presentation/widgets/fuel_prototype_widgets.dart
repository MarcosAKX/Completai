// Componentes visuais removíveis junto com o mockup de descoberta.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/fuel_prototype_station.dart';
import '../../domain/opening_hours.dart';
import '../viewmodels/fuel_discovery_prototype_viewmodel.dart';

String prototypeFuelLabel(PrototypeFuel fuel) => switch (fuel) {
  PrototypeFuel.gasoline => 'Gasolina',
  PrototypeFuel.ethanol => 'Etanol',
  PrototypeFuel.diesel => 'Diesel',
};

class PrototypeFuelSelector extends StatelessWidget {
  const PrototypeFuelSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final PrototypeFuel selected;
  final ValueChanged<PrototypeFuel> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primary,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meu combustível',
          style: AppTextStyles.label.copyWith(color: AppColors.onPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: PrototypeFuel.values.map((fuel) {
            final active = fuel == selected;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(fuel),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.surface
                          : AppColors.onPrimary.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '⛽  ${prototypeFuelLabel(fuel)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: active ? AppColors.primary : AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

class PrototypeStationCard extends StatelessWidget {
  const PrototypeStationCard({
    super.key,
    required this.station,
    required this.selectedFuel,
    required this.onTap,
    this.best = false,
  });
  final FuelPrototypeStation station;
  final PrototypeFuel selectedFuel;
  final VoidCallback onTap;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final open = isWithinOpeningHours(
      now: DateTime.now(),
      schedule: station.openingHours,
    );
    final days = DateTime.now().difference(station.pricesUpdatedAt).inDays;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: best
              ? const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.screenBackground,
                    child: Text(station.name.characters.first),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: AppTextStyles.label.copyWith(fontSize: 16),
                        ),
                        Text(
                          station.neighborhood,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(open: open),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: PrototypeFuel.values
                    .map(
                      (fuel) => Expanded(
                        child: _PriceCell(
                          fuel: fuel,
                          price: station.priceFor(fuel),
                          selected: fuel == selectedFuel,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.accent, size: 15),
                  Expanded(
                    child: Text(
                      ' ${station.rating.toStringAsFixed(1)} · ${station.reviewCount} avaliações',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  Text(
                    ' há $days d',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _PriceCell extends StatelessWidget {
  const _PriceCell({
    required this.fuel,
    required this.price,
    required this.selected,
  });
  final PrototypeFuel fuel;
  final double price;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 3),
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: selected ? AppColors.primaryLight : AppColors.screenBackground,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.outline,
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prototypeFuelLabel(fuel).toUpperCase(),
          maxLines: 1,
          style: AppTextStyles.caption.copyWith(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
          style: AppTextStyles.label.copyWith(
            fontSize: 16,
            color: selected ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.open});
  final bool open;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: open ? const Color(0xFFE8F8EF) : AppColors.screenBackground,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      open ? '◷  Aberto agora' : 'Fechado',
      style: AppTextStyles.caption.copyWith(
        fontSize: 10,
        color: open ? const Color(0xFF178044) : AppColors.textSecondary,
      ),
    ),
  );
}

class PrototypeSpecialState extends StatelessWidget {
  const PrototypeSpecialState({
    super.key,
    required this.state,
    required this.onChooseCity,
  });
  final PrototypeScreenState state;
  final VoidCallback onChooseCity;
  @override
  Widget build(BuildContext context) {
    final loading = state == PrototypeScreenState.loading;
    final denied = state == PrototypeScreenState.locationDenied;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          if (loading)
            const CircularProgressIndicator()
          else
            Icon(
              denied
                  ? Icons.location_off_outlined
                  : Icons.local_gas_station_outlined,
              size: 54,
              color: AppColors.primary,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            loading
                ? 'Buscando postos'
                : denied
                ? 'Onde você está?'
                : 'Nenhum posto por aqui',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            loading
                ? 'Isso leva apenas um instante.'
                : denied
                ? 'Não foi possível acessar o GPS. Escolha uma cidade para continuar.'
                : 'Ainda não há postos cadastrados nesta cidade.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (!loading) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onChooseCity,
              child: const Text('Escolher outra cidade'),
            ),
          ],
        ],
      ),
    );
  }
}

class PrototypeDiscoveryHeader extends StatelessWidget {
  const PrototypeDiscoveryHeader({
    super.key,
    required this.state,
    required this.onCityTap,
    required this.onSearch,
  });
  final FuelDiscoveryPrototypeState state;
  final VoidCallback onCityTap;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Onde completar hoje?',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w500),
        ),
        TextButton.icon(
          onPressed: onCityTap,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          icon: const Icon(Icons.location_on_outlined, size: 18),
          label: Text(
            '${state.city} · ${state.visibleStations.length} postos encontrados  ⌄',
          ),
        ),
        TextField(
          onChanged: onSearch,
          decoration: const InputDecoration(
            hintText: 'Buscar posto ou bairro',
            prefixIcon: Icon(Icons.search),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    ),
  );
}

class PrototypeLoadedList extends StatelessWidget {
  const PrototypeLoadedList({
    super.key,
    required this.state,
    required this.onOnlyOpen,
    required this.onStationTap,
  });
  final FuelDiscoveryPrototypeState state;
  final ValueChanged<bool> onOnlyOpen;
  final ValueChanged<FuelPrototypeStation> onStationTap;

  @override
  Widget build(BuildContext context) {
    final stations = state.visibleStations;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Troque de combustível', style: AppTextStyles.label),
            ),
            const Icon(Icons.close, color: AppColors.primary),
          ],
        ),
        Text(
          'Toque nas opções acima ou deslize a lista para os lados.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              'Só abertos',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Switch(value: state.onlyOpen, onChanged: onOnlyOpen),
            const Spacer(),
            const Icon(Icons.tune, color: AppColors.primary),
            const Text(' Filtros', style: TextStyle(color: AppColors.primary)),
          ],
        ),
        if (stations.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                Text(
                  'Menor preço de ${prototypeFuelLabel(state.fuel)}',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
                if (state.priceGap != null)
                  Text(
                    'R\$ ${state.priceGap!.toStringAsFixed(2).replaceAll('.', ',')}/L abaixo do próximo preço',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF178044),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (stations.isEmpty)
          PrototypeSpecialState(
            state: PrototypeScreenState.empty,
            onChooseCity: () {},
          )
        else
          for (var index = 0; index < stations.length; index++) ...[
            PrototypeStationCard(
              station: stations[index],
              selectedFuel: state.fuel,
              best: index == 0,
              onTap: () => onStationTap(stations[index]),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}
