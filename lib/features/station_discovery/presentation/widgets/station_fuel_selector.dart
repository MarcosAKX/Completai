// Seletor amplo e acessível de combustível, com seleção animada e responsiva.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/station_summary.dart';

class StationFuelSelector extends StatelessWidget {
  const StationFuelSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final FuelType selected;
  final ValueChanged<FuelType> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: FuelType.values.map((fuel) {
      final isSelected = selected == fuel;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: StationFuelOption(
            key: ValueKey(
              isSelected ? 'fuel-selected-${fuel.name}' : 'fuel-${fuel.name}',
            ),
            fuel: fuel,
            selected: isSelected,
            onTap: () => onSelected(fuel),
          ),
        ),
      );
    }).toList(growable: false),
  );
}

class StationFuelOption extends StatelessWidget {
  const StationFuelOption({
    required this.fuel,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final FuelType fuel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: _label,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 68),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: selected ? 1 : .28),
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x330E2E9E),
                  offset: Offset(0, 5),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_gas_station_outlined,
                  size: 22,
                  color: selected ? AppColors.primary : Colors.white,
                ),
                const SizedBox(height: 5),
                Text(
                  _label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? AppColors.primary : Colors.white,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String get _label => switch (fuel) {
    FuelType.gasoline => 'Gasolina',
    FuelType.ethanol => 'Etanol',
    FuelType.diesel => 'Diesel',
  };
}
