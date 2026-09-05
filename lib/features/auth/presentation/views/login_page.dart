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
  // Chave do formulário, usada para validar todos os campos de uma vez.
  final _form = GlobalKey<FormState>();

  // Controllers dos campos de e-mail e senha.
  final _email = TextEditingController();
  final _password = TextEditingController();

  // Se true, a senha aparece oculta (pontinhos); se false, aparece em texto.
  bool _obscure = true;

  @override
  void dispose() {
    // Libera os controllers quando a tela é destruída.
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Executado ao tocar em "Entrar": valida o formulário e chama a
  // ViewModel para autenticar.
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(loginViewModelProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    // Estado atual da ViewModel (carregando, erro ou dado).
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

    // Altura da tela do aparelho.
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Altura do bloco azul: 18% da altura da tela, entre 130px e 170px.
    final heroHeight = (screenHeight * .18).clamp(130.0, 170.0);

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      // Permite rolar a tela caso o conteúdo não caiba.
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bloco azul do topo (hero): título, frase e ilustração.
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
                      // Nome do app.
                      Text(
                        'Completai!',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Frase de destaque abaixo do nome do app.
                      Text(
                        'Seu próximo\nabastecimento\ncomeça aqui',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Ilustração SVG do posto/rota.
                      SizedBox(
                        width: double.infinity,
                        height: 80,
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

            // Bloco do formulário: fundo lilás claro, card branco por cima.
            Transform.translate(
              // Sobrepõe 1px no hero para não deixar uma linha entre as cores.
              offset: const Offset(0, -1),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(color: AppColors.primaryLight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card branco com o formulário de login.
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
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
                            // Título do card.
                            Text(
                              'Entre na sua conta',
                              style: AppTextStyles.title.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Campo de e-mail.
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

                            // Campo de senha, com botão para mostrar/ocultar.
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

                            // Mensagem de erro, exibida quando `error` não é nulo.
                            AuthErrorMessage(error: error),

                            // Botão de login; mostra spinner enquanto carrega.
                            AppButton(
                              label: 'Entrar',
                              isLoading: isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Link para a tela de recuperação de senha.
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
                    const SizedBox(height: AppSpacing.md),

                    // Texto acima do botão de criar conta.
                    Text(
                      'Ainda não tem conta?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Botão de contorno que leva à escolha de perfil (cliente ou posto).
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

                    // Frase final de reforço de marca.
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