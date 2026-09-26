// Segunda etapa: cidade fixa no MVP; a UF é derivada e validada pela geocodificação.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_read_only_field.dart';
import '../../../../core/widgets/app_step_progress.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/models/service_area.dart';
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
  final _street = TextEditingController(),
      _number = TextEditingController(),
      _neighborhood = TextEditingController(),
      _cep = TextEditingController();
  @override
  void dispose() {
    _street.dispose();
    _number.dispose();
    _neighborhood.dispose();
    _cep.dispose();
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
            street: _street.text,
            number: _number.text,
            neighborhood: _neighborhood.text,
            city: ServiceArea.primaryCity,
            cep: _cep.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(stationRegistrationViewModelProvider, (previous, next) {
      if (previous?.isLoading == true && next.valueOrNull == true) {
        Navigator.popUntil(context, (route) => route.isFirst);
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Cadastro concluído! Faça login para continuar.'),
          ),
        );
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
              label: 'Rua / Avenida',
              controller: _street,
              validator: requiredField,
              hintText: 'Ex: Avenida Brasil',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.signpost_outlined),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Número',
                    controller: _number,
                    validator: streetNumberField,
                    hintText: '1000',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    label: 'CEP',
                    controller: _cep,
                    validator: cepField,
                    hintText: '14700-000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [cepInputFormatter],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Bairro',
              controller: _neighborhood,
              validator: requiredField,
              hintText: 'Ex: Centro',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.map_outlined),
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