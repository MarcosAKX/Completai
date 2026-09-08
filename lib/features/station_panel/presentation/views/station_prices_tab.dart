// Aba "Preços": prévia do cliente + edição dos preços por litro.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/station_fuel.dart';
import '../providers/station_panel_providers.dart';
import '../widgets/station_client_preview_card.dart';
import '../widgets/station_panel_section_header.dart';
import '../widgets/station_price_field.dart';
import 'station_display_edit_page.dart';

class StationPricesTab extends ConsumerStatefulWidget {
  const StationPricesTab({super.key});

  @override
  ConsumerState<StationPricesTab> createState() => _StationPricesTabState();
}

class _StationPricesTabState extends ConsumerState<StationPricesTab> {
  final _form = GlobalKey<FormState>();
  final _controllers = {
    for (final fuel in StationFuel.values) fuel: TextEditingController(),
  };
  var _seeded = <StationFuel, double?>{};
  var _publishing = false;

  @override
  void initState() {
    super.initState();
    _seed(ref.read(stationPanelViewModelProvider).valueOrNull?.prices);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _seed(Map<StationFuel, double?>? prices) {
    _seeded = prices ?? {for (final fuel in StationFuel.values) fuel: null};
    for (final fuel in StationFuel.values) {
      _controllers[fuel]!.text = formatFuelPrice(_seeded[fuel]);
    }
  }

  double? _parsed(StationFuel fuel) {
    try {
      return parseFuelPrice(_controllers[fuel]!.text);
    } on FormatException {
      return _seeded[fuel];
    }
  }

  bool _changed(StationFuel fuel) => _parsed(fuel) != _seeded[fuel];

  List<StationFuel> get _dirty =>
      StationFuel.values.where(_changed).toList(growable: false);

  Future<void> _publish() async {
    if (!_form.currentState!.validate() || _dirty.isEmpty) return;
    setState(() => _publishing = true);
    final ok = await ref
        .read(stationPanelViewModelProvider.notifier)
        .savePrices({for (final fuel in _dirty) fuel: _parsed(fuel)});
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = ref.read(stationPanelViewModelProvider).error?.toString();
    if (ok) _seed(ref.read(stationPanelViewModelProvider).valueOrNull?.prices);
    setState(() => _publishing = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Preços publicados para os clientes.'
              : error ?? 'Não foi possível publicar. Tente novamente.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(stationPanelViewModelProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final dirtyCount = _dirty.length;

    return Form(
      key: _form,
      onChanged: () => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          StationPanelSectionHeader(
            title: 'Prévia para clientes',
            subtitle: 'Mostra como o posto aparece na busca por combustível.',
            trailing: IconButton(
              tooltip: 'Editar exibição',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StationDisplayEditPage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StationClientPreviewCard(profile: profile),
          const SizedBox(height: AppSpacing.xl),
          const StationPanelSectionHeader(
            title: 'Painel de preços',
            subtitle:
                'Os clientes veem os novos valores assim que você publica.',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final fuel in StationFuel.values) ...[
            StationPriceField(
              fuel: fuel,
              controller: _controllers[fuel]!,
              changed: _changed(fuel),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: dirtyCount == 0
                ? 'Nenhum preço alterado'
                : 'Publicar $dirtyCount ${dirtyCount == 1 ? 'preço' : 'preços'}',
            isLoading: _publishing,
            onPressed: dirtyCount == 0 ? null : _publish,
          ),
        ],
      ),
    );
  }
}
