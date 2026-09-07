// Ação primária de rota, em largura total e sem expor telefone privado.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class StationDirectionsButton extends StatelessWidget {
  const StationDirectionsButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.navigation_rounded),
      label: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Text('Como chegar'),
            Text(
              'Abrir no Google Maps',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    ),
  );
}
