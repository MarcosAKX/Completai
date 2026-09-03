// Cadastro do motorista em duas operações retomáveis: Auth e perfil privado.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/contact_input_formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_page_body.dart';
import '../widgets/auth_validators.dart';

class ClientRegistrationPage extends ConsumerStatefulWidget {
  const ClientRegistrationPage({super.key});
  @override
  ConsumerState<ClientRegistrationPage> createState() =>
      _ClientRegistrationPageState();
}

class _ClientRegistrationPageState
    extends ConsumerState<ClientRegistrationPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _phone = TextEditingController(),
      _password = TextEditingController();
  bool _obscure = true;
  bool _accountCreated = false;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final notifier = ref.read(authViewModelProvider.notifier);
    if (!_accountCreated) {
      await notifier.createAccount(
        email: _email.text,
        password: _password.text,
      );
      if (ref.read(authViewModelProvider).hasError) return;
      _accountCreated = true;
    }
    await notifier.completeClientRegistration(
      name: _name.text,
      phone: _phone.text,
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
        title: const Text('Cadastro - Usuário'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _form,
        child: AuthPageBody(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Torne-se um Usuário',
          subtitle: 'Junte-se ao Completai! e economize agora.',
          children: [
            AppTextField(
              label: 'Nome completo',
              controller: _name,
              validator: requiredField,
              hintText: 'Nome completo',
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'E-mail',
              controller: _email,
              validator: emailField,
              hintText: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Celular',
              controller: _phone,
              validator: phoneField,
              hintText: '(17) 99999-9999',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [phoneInputFormatter],
              prefixIcon: const Icon(Icons.phone_outlined),
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
            AuthErrorMessage(error: auth.error),
            AppButton(
              label: 'Criar Conta',
              isLoading: auth.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Já possui uma conta? Fazer Login'),
            ),
          ],
        ),
      ),
    );
  }
}
