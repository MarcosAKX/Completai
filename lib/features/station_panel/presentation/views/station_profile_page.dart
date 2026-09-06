// Perfil do posto: dados da conta, endereço e sair.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/contact_input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/station_profile.dart';
import '../providers/station_panel_providers.dart';

class StationProfilePage extends ConsumerStatefulWidget {
  const StationProfilePage({super.key});

  @override
  ConsumerState<StationProfilePage> createState() => _StationProfilePageState();
}

class _StationProfilePageState extends ConsumerState<StationProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city = TextEditingController();
  late StationProfile _initial;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _initial = ref.read(stationPanelViewModelProvider).requireValue;
    _name.text = _initial.name;
    _phone.text = _initial.phone;
    _address.text = _initial.address;
    _neighborhood.text = _initial.neighborhood;
    _city.text = _initial.city;
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _address, _neighborhood, _city]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _identityChanged =>
      _name.text.trim() != _initial.name ||
      _phone.text.trim() != _initial.phone;

  bool get _addressChanged =>
      _address.text.trim() != _initial.address ||
      _neighborhood.text.trim() != _initial.neighborhood ||
      _city.text.trim() != _initial.city;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_identityChanged && !_addressChanged) return;
    setState(() => _saving = true);
    final notifier = ref.read(stationPanelViewModelProvider.notifier);
    var ok = true;
    if (_identityChanged) {
      ok = await notifier.saveIdentity(
        name: _name.text,
        phone: _phone.text,
      );
    }
    if (ok && _addressChanged) {
      ok = await notifier.saveAddress(
        address: _address.text,
        neighborhood: _neighborhood.text,
        city: _city.text,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      setState(
        () => _initial = ref.read(stationPanelViewModelProvider).requireValue,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Dados do posto atualizados.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ref.read(stationPanelViewModelProvider).error?.toString() ??
                'Não foi possível salvar.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final changed = _identityChanged || _addressChanged;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Perfil do posto'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Dados da conta', style: AppTextStyles.title.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Nome do posto',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Informe o nome do posto'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _ReadOnlyField(label: 'CNPJ', value: _initial.cnpj),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Celular',
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneInputFormatter],
              validator: (value) => (value ?? '').trim().length < 14
                  ? 'Informe um telefone válido'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Endereço', style: AppTextStyles.title.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Alterar o endereço confirma a localização e a cidade pela geocodificação (somente São Paulo).',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Endereço',
              controller: _address,
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Bairro',
              controller: _neighborhood,
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Cidade',
              controller: _city,
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: changed ? 'Salvar alterações' : 'Nada para salvar',
              isLoading: _saving,
              onPressed: changed ? _save : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Sair da conta',
              outlined: true,
              onPressed: _saving ? null : _signOut,
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Campo obrigatório' : null;

  Future<void> _signOut() async {
    await ref.read(sessionViewModelProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: AppSpacing.sm),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.screenBackground,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          border: Border.all(color: AppColors.outline),
        ),
        child: Text(
          value.isEmpty ? '—' : value,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}
