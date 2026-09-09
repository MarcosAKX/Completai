// Resumo privado do motorista; coordena navegação e ações dos ViewModels.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/client_profile_providers.dart';
import '../widgets/client_profile_summary.dart';
import '../widgets/client_profile_card.dart';
import 'client_profile_edit_page.dart';

class ClientProfilePage extends ConsumerWidget {
  const ClientProfilePage({super.key});

  Future<void> _resetPassword(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    await ref.read(passwordResetViewModelProvider.notifier).send(email);
    if (!context.mounted) return;
    final result = ref.read(passwordResetViewModelProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.hasError
              ? result.error.toString()
              : 'E-mail de redefinição enviado. Confira sua caixa de entrada.',
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionViewModelProvider.notifier).signOut();
    if (!context.mounted) return;
    final session = ref.read(sessionViewModelProvider);
    if (session.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(session.error.toString())));
    } else if (session.valueOrNull == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionViewModelProvider);
    final uid = session.valueOrNull?.uid;
    final password = ref.watch(passwordResetViewModelProvider);
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
      ),
      body: uid == null
          ? Center(
              child: session.hasError
                  ? Text(session.error.toString())
                  : const CircularProgressIndicator(),
            )
          : ref
                .watch(clientProfileViewModelProvider(uid))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error.toString()),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: 'Tentar novamente',
                            onPressed: () => ref.invalidate(
                              clientProfileViewModelProvider(uid),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (profile) => SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          ClientProfileSummary(
                            profile: profile,
                            onEdit: () async {
                              final saved = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => ClientProfileEditPage(
                                        profile: profile,
                                      ),
                                    ),
                                  );
                              if (context.mounted && saved == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dados atualizados.'),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ClientProfileCard(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Segurança',
                                    style: AppTextStyles.title,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextButton.icon(
                                    onPressed: password.isLoading
                                        ? null
                                        : () => _resetPassword(
                                            context,
                                            ref,
                                            profile.email,
                                          ),
                                    icon: const Icon(Icons.lock_reset_outlined),
                                    label: Text(
                                      password.isLoading
                                          ? 'Enviando e-mail…'
                                          : 'Redefinir senha',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: 'Sair da conta',
                            outlined: true,
                            isLoading: session.isLoading,
                            onPressed: () => _signOut(context, ref),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Seus dados de conta são privados.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
