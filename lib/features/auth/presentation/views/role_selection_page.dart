// Escolha do papel antes de criar credenciais ou documentos no Firestore.
import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_selection_card.dart';
import '../../../../core/widgets/app_step_progress.dart';
import '../widgets/auth_page_body.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.screenBackground,
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: AuthPageBody(
      header: const AppStepProgress(current: 1),
      title: 'Bem-vindo(a)!',
      subtitle: 'Como você deseja utilizar nossa plataforma hoje?',
      children: [
        AppSelectionCard(
          icon: Icons.directions_car_outlined,
          title: 'Motorista',
          description: 'Compare preços, horários e avaliações dos postos.',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.clientRegistration),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSelectionCard(
          icon: Icons.local_gas_station_outlined,
          title: 'Posto de Combustível',
          description: 'Mantenha preços, horários e serviços atualizados.',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.stationRegistrationStep1),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (_) => false,
          ),
          child: const Column(
            children: [
              Text('Já possui uma conta?'),
              SizedBox(height: AppSpacing.sm),
              Text('Fazer login'),
            ],
          ),
        ),
      ],
    ),
  );
}
