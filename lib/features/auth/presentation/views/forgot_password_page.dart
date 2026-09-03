// Recuperação de senha no padrão AppBar + ícone + card.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_page_body.dart';
import '../widgets/auth_validators.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(passwordResetViewModelProvider.notifier).send(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(passwordResetViewModelProvider, (previous, next) {
      if (previous?.isLoading == true && next.valueOrNull == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enviamos as instruções para o seu e-mail.'),
          ),
        );
      }
    });
    final reset = ref.watch(passwordResetViewModelProvider);
    final isLoading = reset.when(
      data: (_) => false,
      loading: () => true,
      error: (_, _) => false,
    );
    final error = reset.when<Object?>(
      data: (_) => null,
      loading: () => null,
      error: (error, _) => error,
    );
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _form,
        child: AuthPageBody(
          icon: Icons.lock_reset_outlined,
          title: 'Esqueceu sua senha?',
          subtitle: 'Informe seu e-mail para receber o link de recuperação.',
          card: true,
          children: [
            AppTextField(
              label: 'E-mail',
              controller: _email,
              validator: emailField,
              hintText: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthErrorMessage(error: error),
            AppButton(
              label: 'Enviar e-mail',
              isLoading: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
