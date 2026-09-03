// Segunda etapa: cidade editável; a UF é derivada e validada pela geocodificação.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_step_progress.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/station_registration.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_page_body.dart';
import '../widgets/auth_validators.dart';

class StationRegistrationStep2Page extends ConsumerStatefulWidget {
  const StationRegistrationStep2Page({super.key, required this.draft});
  final StationRegistrationDraft draft;
  @override
  ConsumerState<StationRegistrationStep2Page> createState() =>
      _StationRegistrationStep2PageState();
}

class _StationRegistrationStep2PageState
    extends ConsumerState<StationRegistrationStep2Page> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController(),
      _neighborhood = TextEditingController(),
      _city = TextEditingController();
  bool _accountCreated = false;
  @override
  void dispose() {
    _address.dispose();
    _neighborhood.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final notifier = ref.read(authViewModelProvider.notifier);
    if (!_accountCreated) {
      await notifier.createAccount(
        email: widget.draft.email,
        password: widget.draft.password,
      );
      if (ref.read(authViewModelProvider).hasError) return;
      _accountCreated = true;
    }
    await notifier.completeStationRegistration(
      StationRegistration(
        cnpj: widget.draft.cnpj,
        brandName: widget.draft.brandName,
        phone: widget.draft.phone,
        address: _address.text,
        neighborhood: _neighborhood.text,
        city: _city.text,
      ),
    );
    if (mounted && !ref.read(authViewModelProvider).hasError) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Endereço do Posto'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _form,
        child: AuthPageBody(
          header: const AppStepProgress(current: 2),
          icon: Icons.location_on_outlined,
          title: 'Localização',
          subtitle: 'Informe o endereço do posto.',
          children: [
            AppTextField(
              label: 'Endereço',
              controller: _address,
              validator: requiredField,
              hintText: 'Ex: Avenida Brasil, 1000',
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Bairro',
              controller: _neighborhood,
              validator: requiredField,
              hintText: 'Ex: Centro',
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Cidade',
              controller: _city,
              validator: requiredField,
              hintText: 'Ex: Campinas',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthErrorMessage(error: auth.error),
            AppButton(
              label: 'Finalizar Cadastro',
              isLoading: auth.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
