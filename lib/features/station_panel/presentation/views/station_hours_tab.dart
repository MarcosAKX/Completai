// Aba "Horários": funcionamento por dia da semana.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/opening_hours.dart';
import '../providers/station_panel_providers.dart';
import '../widgets/station_hours_day_row.dart';
import '../widgets/station_panel_section_header.dart';

class StationHoursTab extends ConsumerStatefulWidget {
  const StationHoursTab({super.key});

  @override
  ConsumerState<StationHoursTab> createState() => _StationHoursTabState();
}

class _StationHoursTabState extends ConsumerState<StationHoursTab> {
  late WeeklyHours _hours;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _hours = ref.read(stationPanelViewModelProvider).requireValue.openingHours;
  }

  bool get _dirty {
    final saved =
        ref.read(stationPanelViewModelProvider).requireValue.openingHours;
    return _hours != saved;
  }

  void _copyToAll() {
    final firstOpen = Weekday.values
        .map(_hours.forDay)
        .firstWhere((h) => h != null, orElse: () => null);
    if (firstOpen == null) return;
    setState(() => _hours = _hours.filledWith(firstOpen));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref
        .read(stationPanelViewModelProvider.notifier)
        .saveOpeningHours(_hours);
    if (!mounted) return;
    final error = ref.read(stationPanelViewModelProvider).error?.toString();
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Horários atualizados.' : error ?? 'Não foi possível salvar.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anyOpen = Weekday.values.any(_hours.isOpen);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        StationPanelSectionHeader(
          title: 'Horários',
          subtitle: 'O cliente vê se o posto está aberto agora.',
          trailing: TextButton.icon(
            onPressed: anyOpen ? _copyToAll : null,
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: const Text('Copiar p/ todos'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final day in Weekday.values)
          StationHoursDayRow(
            day: day,
            hours: _hours.forDay(day),
            onChanged: (value) =>
                setState(() => _hours = _hours.withDay(day, value)),
          ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: _dirty ? 'Salvar horários' : 'Nada para salvar',
          isLoading: _saving,
          onPressed: _dirty ? _save : null,
        ),
      ],
    );
  }
}
