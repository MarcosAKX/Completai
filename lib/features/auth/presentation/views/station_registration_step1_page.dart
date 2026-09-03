// Primeira etapa: valida e transporta dados sem gravar conta ou Firestore.
import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_step_progress.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/station_registration.dart';
import '../widgets/auth_page_body.dart';
import '../widgets/auth_validators.dart';

class StationRegistrationStep1Page extends StatefulWidget {
  const StationRegistrationStep1Page({super.key});
  @override
  State<StationRegistrationStep1Page> createState() =>
      _StationRegistrationStep1PageState();
}

class _StationRegistrationStep1PageState
    extends State<StationRegistrationStep1Page> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _cnpj = TextEditingController(),
      _phone = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _name.dispose();
    _cnpj.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    Navigator.pushNamed(
      context,
      AppRoutes.stationRegistrationStep2,
      arguments: StationRegistrationDraft(
        brandName: _name.text,
        cnpj: _cnpj.text,
        phone: _phone.text,
        email: _email.text,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.screenBackground,
    appBar: AppBar(
      title: const Text('Cadastro do Posto'),
      backgroundColor: Colors.transparent,
    ),
    body: Form(
      key: _form,
      child: AuthPageBody(
        header: const AppStepProgress(current: 1),
        icon: Icons.local_gas_station,
        title: 'Dados do Posto',
        subtitle: 'Informe os dados básicos para criar a conta administrativa.',
        children: [
          AppTextField(
            label: 'Nome do posto',
            controller: _name,
            validator: requiredField,
            hintText: 'Ex: Posto Avenida',
            prefixIcon: const Icon(Icons.store_outlined),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'CNPJ',
            controller: _cnpj,
            validator: cnpjField,
            hintText: 'Digite apenas números',
            keyboardType: TextInputType.number,
            inputFormatters: [cnpjInputFormatter],
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Telefone',
            controller: _phone,
            validator: phoneField,
            hintText: '(17) 99999-9999',
            keyboardType: TextInputType.phone,
            inputFormatters: [phoneInputFormatter],
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'E-mail administrativo',
            controller: _email,
            validator: emailField,
            hintText: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Senha',
            controller: _password,
            validator: passwordField,
            hintText: '********',
            obscureText: _obscure,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Próximo', onPressed: _next),
        ],
      ),
    ),
  );
}
