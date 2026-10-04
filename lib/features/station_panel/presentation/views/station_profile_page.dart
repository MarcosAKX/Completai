// Perfil do posto: dados da conta, endereço e sair.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/contact_input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_read_only_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/models/service_area.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_validators.dart';
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
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _neighborhood = TextEditingController();
  final _cep = TextEditingController();
  late StationProfile _initial;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _initial = ref.read(stationPanelViewModelProvider).requireValue;
    _name.text = _initial.name;
    _phone.text = _initial.phone;
    _street.text = _initial.street;
    _number.text = _initial.number;
    _neighborhood.text = _initial.neighborhood;
    _cep.text = cepMask(_initial.cep);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _street,
      _number,
      _neighborhood,
      _cep,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _identityChanged =>
      _name.text.trim() != _initial.name ||
      _phone.text.trim() != _initial.phone;

  String get _cepDigits => _cep.text.replaceAll(RegExp(r'\D'), '');

  // A cidade não entra na comparação: é fixa no MVP e sempre reenviada como
  // `ServiceArea.primaryCity` junto com qualquer mudança de endereço.
  bool get _addressChanged =>
      _street.text.trim() != _initial.street ||
      _number.text.trim() != _initial.number ||
      _neighborhood.text.trim() != _initial.neighborhood ||
      _cepDigits != _initial.cep;

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
        street: _street.text,
        number: _number.text,
        neighborhood: _neighborhood.text,
        city: ServiceArea.primaryCity,
        cep: _cep.text,
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
            AppReadOnlyField(label: 'CNPJ', value: _initial.cnpj),
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
              'Alterar o endereço confirma a localização pela geocodificação. A cidade é fixa nesta fase do projeto.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Rua / Avenida',
              controller: _street,
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Número',
                    controller: _number,
                    hintText: '1000',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    label: 'CEP',
                    controller: _cep,
                    hintText: '14700-000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [cepInputFormatter],
                    validator: optionalCepField,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Bairro',
              controller: _neighborhood,
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            const AppReadOnlyField(
              label: 'Cidade',
              value: ServiceArea.primaryCity,
              icon: Icons.location_city_outlined,
              helperText:
                  'O CompletAI atende apenas ${ServiceArea.primaryCity} nesta fase.',
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

