// Capa pública única do posto, com fallback visual quando não há foto.
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StationDetailsHeader extends StatelessWidget {
  const StationDetailsHeader({this.imageBytes, super.key});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 8.5,
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: imageBytes == null
          ? const ColoredBox(
              color: AppColors.primaryLight,
              child: Center(
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
            )
          : Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.primaryLight,
                child: Center(
                  child: Icon(
                    Icons.local_gas_station_rounded,
                    size: 72,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
    ),
  );
}
