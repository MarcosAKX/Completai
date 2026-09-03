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
  @override
  void dispose() {
    _address.dispose();
    _neighborhood.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(stationRegistrationViewModelProvider.notifier)
        .register(
          email: widget.draft.email,
          password: widget.draft.password,
          registration: StationRegistration(
            cnpj: widget.draft.cnpj,
            brandName: widget.draft.brandName,
            phone: widget.draft.phone,
            address: _address.text,
            neighborhood: _neighborhood.text,
            city: _city.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(stationRegistrationViewModelProvider, (previous, next) {
      if (previous?.isLoading == true && next.valueOrNull == true) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
    final registration = ref.watch(stationRegistrationViewModelProvider);
    final isLoading = registration.when(
      data: (_) => false,
      loading: () => true,
      error: (_, _) => false,
    );
    final error = registration.when<Object?>(
      data: (_) => null,
      loading: () => null,
      error: (error, _) => error,
    );
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
            AuthErrorMessage(error: error),
            AppButton(
              label: 'Finalizar Cadastro',
              isLoading: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
