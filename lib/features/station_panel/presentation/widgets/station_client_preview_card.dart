// "Prévia para clientes": espelha como o posto aparece para o motorista.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/station_brand_badge.dart';
import '../../../station_cover/presentation/providers/station_cover_providers.dart';
import '../../domain/models/station_profile.dart';

class StationClientPreviewCard extends ConsumerWidget {
  const StationClientPreviewCard({
    super.key,
    required this.profile,
    this.pendingCoverBytes,
    this.pendingCoverRemoved = false,
  });

  final StationProfile profile;

  /// Foto escolhida mas ainda não salva (tela "Editar exibição").
  final Uint8List? pendingCoverBytes;

  /// Remoção de foto ainda não salva.
  final bool pendingCoverRemoved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = [
      profile.address,
      profile.neighborhood,
      profile.city,
    ].where((part) => part.trim().isNotEmpty).join(' • ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto grande e limpa — o dono precisa reconhecer o posto.
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _cover(ref),
                  Positioned(
                    left: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: StationBrandBadge(brand: profile.brand),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name.isEmpty ? 'Seu posto' : profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(fontSize: 19),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _PreviewChip(
                        icon: Icons.local_gas_station_outlined,
                        label:
                            '${profile.informedFuelCount} ${profile.informedFuelCount == 1 ? 'combustível' : 'combustíveis'}',
                      ),
                      _PreviewChip(
                        icon: Icons.build_outlined,
                        label:
                            '${profile.serviceCount} ${profile.serviceCount == 1 ? 'serviço' : 'serviços'}',
                      ),
                      _PreviewChip(
                        icon: Icons.schedule_outlined,
                        label: profile.openingHoursInformed
                            ? 'Horário definido'
                            : 'Horário a definir',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(WidgetRef ref) {
    if (pendingCoverBytes != null) {
      return Image.memory(pendingCoverBytes!, fit: BoxFit.cover);
    }
    if (pendingCoverRemoved) return const _CoverFallback();
    return ref
        .watch(stationCoverProvider(profile.uid))
        .when(
          loading: () => const _CoverFallback(loading: true),
          error: (_, _) => const _CoverFallback(),
          data: (cover) => cover == null
              ? const _CoverFallback()
              : Image.memory(cover.bytes, fit: BoxFit.cover),
        );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ),
    ),
    child: Center(
      child: loading
          ? const SizedBox.square(
              dimension: AppSpacing.lg,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Adicione uma foto do posto',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
    ),
  );
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
        ),
      ],
    ),
  );
}
