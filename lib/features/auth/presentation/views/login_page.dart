// Login responsivo no padrão hero compacto + card do DESIGN.md.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_validators.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(loginViewModelProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final login = ref.watch(loginViewModelProvider);
    final isLoading = login.when(
      data: (_) => false,
      loading: () => true,
      error: (_, _) => false,
    );
    final error = login.when<Object?>(
      data: (_) => null,
      loading: () => null,
      error: (error, _) => error,
    );
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * .34).clamp(240.0, 300.0);
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints(minHeight: heroHeight),
              width: double.infinity,
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36, 16, 36, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completai!',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Seu próximo\nabastecimento\ncomeça aqui',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 90,
                        child: SvgPicture.asset(
                          'assets/images/auth_hero.svg',
                          fit: BoxFit.contain,
                          semanticsLabel: 'Rota até um posto de combustível',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -1),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: screenHeight - heroHeight,
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(color: AppColors.primaryLight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withValues(alpha: .05),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Entre na sua conta',
                              style: AppTextStyles.title.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              label: 'E-mail',
                              controller: _email,
                              validator: emailField,
                              hintText: 'Seu e-mail',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              prefixIcon: const Icon(Icons.mail_outline),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Senha',
                              controller: _password,
                              validator: passwordField,
                              hintText: '••••••••',
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AuthErrorMessage(error: error),
                            AppButton(
                              label: 'Entrar',
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.forgotPassword,
                              ),
                              child: const Text('Esqueci minha senha'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Ainda não tem conta?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Criar conta',
                      outlined: true,
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushNamed(
                              context,
                              AppRoutes.roleSelection,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Preços locais para decisões mais rápidas.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
