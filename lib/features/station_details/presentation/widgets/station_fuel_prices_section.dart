// Grade responsiva dos cinco preços públicos do posto.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/station_fuel.dart';
import '../../domain/models/station_details.dart';
import 'station_details_section.dart';

class StationFuelPricesSection extends StatelessWidget {
  const StationFuelPricesSection({required this.details, super.key});

  final StationDetails details;

  @override
  Widget build(BuildContext context) => StationDetailsSection(
    icon: Icons.local_gas_station_outlined,
    title: 'Preços de combustível',
    trailing: Text(
      _updated(details.pricesUpdatedAt),
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final fuel in StationFuel.values)
              SizedBox(
                width: width,
                child: _PriceTile(fuel: fuel, price: details.priceFor(fuel)),
              ),
          ],
        );
      },
    ),
  );
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({required this.fuel, required this.price});

  final StationFuel fuel;
  final double? price;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.outline),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_gas_station_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fuel.label,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                price == null
                    ? 'Não informado'
                    : 'R\$ ${price!.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _updated(DateTime? date) {
  if (date == null) return 'Sem atualização';
  final difference = DateTime.now().difference(date);
  if (difference.inDays == 0) return 'Atualizado hoje';
  return 'Há ${difference.inDays} dias';
}
