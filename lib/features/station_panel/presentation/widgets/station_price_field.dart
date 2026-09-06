// Campo de preço por litro de um combustível, com prefixo R$ e validação.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../domain/models/station_fuel.dart';

class StationPriceField extends StatelessWidget {
  const StationPriceField({
    super.key,
    required this.fuel,
    required this.controller,
    required this.changed,
    this.onChanged,
  });

  final StationFuel fuel;
  final TextEditingController controller;

  /// Marca visualmente que o valor difere do publicado.
  final bool changed;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(fuel.label, style: AppTextStyles.label)),
            if (changed)
              Text(
                'não publicado',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [FuelPriceInputFormatter()],
          style: AppTextStyles.body,
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            hintText: '0,000',
            filled: true,
            fillColor: changed
                ? AppColors.primaryLight
                : Theme.of(context).colorScheme.surface,
          ),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return null;
            final double? price;
            try {
              price = parseFuelPrice(text);
            } on FormatException {
              return 'Preço inválido';
            }
            if (price == null) return null;
            if (price < kMinFuelPrice || price > kMaxFuelPrice) {
              return 'Entre R\$ ${formatFuelPrice(kMinFuelPrice)} e R\$ ${formatFuelPrice(kMaxFuelPrice)}';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Preço por litro',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
