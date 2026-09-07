// Serviços públicos traduzidos para rótulos e ícones consistentes.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'station_details_section.dart';

class StationServicesSection extends StatelessWidget {
  const StationServicesSection({required this.services, super.key});

  final List<String> services;

  @override
  Widget build(BuildContext context) => StationDetailsSection(
    icon: Icons.settings_outlined,
    title: 'Serviços disponíveis',
    child: services.isEmpty
        ? const Text(
            'Nenhum serviço informado.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        : Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final service in services)
                Chip(
                  avatar: Icon(
                    _icon(service),
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(_label(service)),
                  backgroundColor: AppColors.primaryLight,
                  side: BorderSide.none,
                ),
            ],
          ),
  );
}

String _label(String value) => switch (value) {
  'convenience' || 'conveniencia' => 'Conveniência',
  'oil_change' || 'troca_oleo' => 'Troca de óleo',
  'tire_inflation' || 'calibragem' => 'Calibragem',
  'restroom' || 'banheiro' => 'Banheiro',
  'car_wash' || 'lava_rapido' => 'Lava-rápido',
  'app_payment' || 'pagamento_app' => 'Pagamento por app',
  _ => value,
};

IconData _icon(String value) => switch (value) {
  'convenience' || 'conveniencia' => Icons.shopping_cart_outlined,
  'oil_change' || 'troca_oleo' => Icons.oil_barrel_outlined,
  'tire_inflation' || 'calibragem' => Icons.tire_repair_outlined,
  'restroom' || 'banheiro' => Icons.wc_outlined,
  'car_wash' || 'lava_rapido' => Icons.local_car_wash_outlined,
  'app_payment' || 'pagamento_app' => Icons.phone_android_outlined,
  _ => Icons.check_circle_outline,
};
