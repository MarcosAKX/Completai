// Card público de um favorito; foto sob demanda e ações separadas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/station_hours_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/station_logo.dart';
import '../../../../shared/models/station_fuel.dart';
import '../../../station_cover/presentation/providers/station_cover_providers.dart';
import '../../../station_details/domain/models/station_details.dart';

class FavoriteStationCard extends ConsumerWidget {
  const FavoriteStationCard({
    required this.station,
    required this.onOpen,
    required this.onRemove,
    super.key,
  });
  final StationDetails station;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = ref.watch(stationCoverProvider(station.uid));
    final status = stationHoursStatus(DateTime.now(), station.openingHours);
    final date = station.pricesUpdatedAt;
    final days = date == null ? null : DateTime.now().difference(date).inDays;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.primaryLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StationLogo(
                    stationName: station.name,
                    imageBytes: cover.valueOrNull?.bytes,
                    size: AppSpacing.xxl,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${station.neighborhood} · ${station.city}',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          status.isOpen ? 'Aberto agora' : 'Fechado',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover ${station.name} dos favoritos',
                    onPressed: onRemove,
                    icon: const Icon(Icons.favorite, color: AppColors.primary),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 280 ||
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final entry in const {
                        StationFuel.gasolineRegular: 'GASOLINA',
                        StationFuel.ethanol: 'ETANOL',
                        StationFuel.dieselS10: 'DIESEL S10',
                      }.entries)
                        SizedBox(
                          width: stacked
                              ? constraints.maxWidth
                              : (constraints.maxWidth - AppSpacing.md) / 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.value, style: AppTextStyles.caption),
                              Text(
                                station.priceFor(entry.key) == null
                                    ? 'Não informado'
                                    : 'R\$ ${station.priceFor(entry.key)!.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Divider(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  Text(
                    '★ ${station.averageRating.toStringAsFixed(1).replaceAll('.', ',')} · ${station.reviewCount} avaliações',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    days == null
                        ? 'Sem atualização'
                        : days <= 0
                        ? 'Atualizado hoje'
                        : 'Atualizado há $days ${days == 1 ? 'dia' : 'dias'}',
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
