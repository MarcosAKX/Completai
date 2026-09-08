// Aba "Informações": serviços/comodidades e marcadores do posto.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/station_service_options.dart';
import '../providers/station_panel_providers.dart';
import '../widgets/station_panel_section_header.dart';
import '../widgets/station_tag_input.dart';

class StationInfoTab extends ConsumerStatefulWidget {
  const StationInfoTab({super.key});

  @override
  ConsumerState<StationInfoTab> createState() => _StationInfoTabState();
}

class _StationInfoTabState extends ConsumerState<StationInfoTab> {
  late Set<String> _services;
  late List<String> _tags;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(stationPanelViewModelProvider).requireValue;
    _services = profile.services.toSet();
    _tags = List.of(profile.tags);
  }

  List<String> get _serviceOptions => {
    ...kSuggestedServices,
    ..._services,
  }.toList(growable: false);

  bool get _dirty {
    final profile = ref.read(stationPanelViewModelProvider).requireValue;
    return !setEquals(_services, profile.services.toSet()) ||
        !listEquals(_tags, profile.tags);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ordered = _serviceOptions.where(_services.contains).toList();
    final ok = await ref
        .read(stationPanelViewModelProvider.notifier)
        .saveInfo(services: ordered, tags: _tags);
    if (!mounted) return;
    final error = ref.read(stationPanelViewModelProvider).error?.toString();
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Informações atualizadas.'
              : error ?? 'Não foi possível salvar.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const StationPanelSectionHeader(
          title: 'Serviços',
          subtitle: 'O que o posto oferece além de combustível.',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final service in _serviceOptions)
              FilterChip(
                label: Text(service),
                selected: _services.contains(service),
                onSelected: (on) => setState(() {
                  if (on) {
                    _services.add(service);
                  } else {
                    _services.remove(service);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const StationPanelSectionHeader(
          title: 'Marcadores',
          subtitle: 'Palavras que ajudam o cliente a achar o posto na busca.',
        ),
        const SizedBox(height: AppSpacing.md),
        StationTagInput(
          tags: _tags,
          maxTags: kMaxStationTags,
          onChanged: (tags) => setState(() => _tags = tags),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: _dirty ? 'Salvar informações' : 'Nada para salvar',
          isLoading: _saving,
          onPressed: _dirty ? _save : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_services.length}/$kMaxStationServices serviços · '
          '${_tags.length}/$kMaxStationTags marcadores',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
