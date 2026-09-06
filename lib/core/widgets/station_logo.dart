// Marca visual do posto: quadrado arredondado com a foto, ou fallback com
// iniciais do nome / ícone. Usado na listagem do motorista e na prévia do
// painel. A imagem vem em bytes (station_covers), nunca por URL.
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StationLogo extends StatelessWidget {
  const StationLogo({
    super.key,
    required this.stationName,
    this.imageBytes,
    this.size = 48,
  });

  final String stationName;
  final Uint8List? imageBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    final initials = _initials(stationName);
    final label = stationName.trim().isEmpty ? 'posto' : stationName.trim();

    return Semantics(
      image: true,
      label: 'Logo de $label',
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(size * 0.3),
            border: Border.all(color: AppColors.outline),
            image: bytes == null
                ? null
                : DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
          ),
          child: bytes != null
              ? null
              : initials == null
              ? Icon(
                  Icons.local_gas_station_outlined,
                  color: AppColors.primary,
                  size: size * 0.48,
                )
              : Text(
                  initials,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.34,
                  ),
                ),
        ),
      ),
    );
  }

  String? _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (words.isEmpty) return null;
    return words.map((word) => word[0].toUpperCase()).join();
  }
}
