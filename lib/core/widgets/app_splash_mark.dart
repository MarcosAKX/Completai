// Marca animada exibida durante o carregamento inicial (splash).
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_splash_hose_painter.dart';

// Widget principal da splash. É "Stateful" porque precisa controlar uma
// animação contínua enquanto a tela estiver visível.
class AppSplashMark extends StatefulWidget {
  const AppSplashMark({super.key});

  @override
  State<AppSplashMark> createState() => _AppSplashMarkState();
}

// SingleTickerProviderStateMixin: necessário para criar um
// AnimationController — é o que gera o "tique-taque" da animação.
class _AppSplashMarkState extends State<AppSplashMark>
    with SingleTickerProviderStateMixin {
  // Controla o progresso da animação, de 0.0 a 1.0, repetidamente.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Cria o controller: cada ciclo da animação dura 3200ms (3,2 segundos).
    // `..repeat()` faz ele voltar a 0 e recomeçar automaticamente, sem fim.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    // Libera o controller quando a splash sai de tela — evita vazamento
    // de memória e erro de "setState após dispose".
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    // AnimatedBuilder reconstrói esse trecho toda vez que o valor do
    // _controller muda (o que acontece continuamente, ~60x por segundo).
    animation: _controller,
    builder: (context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ilustração animada da mangueira/bomba (definida em
        // app_splash_hose_painter.dart). Recebe o progresso atual (0 a 1)
        // para saber em que ponto da animação está.
        SplashHoseAnimation(progress: _controller.value),

        // Nome do app.
        Text(
          'Completai!',
          style: AppTextStyles.title.copyWith(
            color: AppColors.onPrimary,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Subtítulo abaixo do nome do app.
        Text(
          'Preparando seu próximo abastecimento',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onPrimary.withValues(alpha: .72),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Três pontinhos de carregamento, também animados com o mesmo
        // progresso do controller.
        _LoadingDots(progress: _controller.value),
      ],
    ),
  );
}

// Os três pontinhos de "carregando..." embaixo do texto.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress});

  // Progresso recebido do AppSplashMark (0.0 a 1.0, em loop contínuo).
  final double progress;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    // Gera 3 pontinhos (index 0, 1, 2).
    children: List.generate(3, (index) {
      // Desloca a "fase" de cada pontinho, para que eles não pisquem
      // todos ao mesmo tempo (cada um começa .25 depois do anterior).
      final phase = (progress * 3 - index * .25) % 1;

      // Calcula a opacidade do pontinho nesse instante: varia entre .25
      // (quase apagado) e 1.0 (totalmente visível), formando um efeito
      // de "pulso" ao longo do ciclo.
      final opacity = .25 + .75 * (1 - (2 * phase - 1).abs());

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Opacity(
          // clamp garante que a opacidade nunca saia do intervalo
          // válido (0.0 a 1.0), mesmo com eventual imprecisão do cálculo.
          opacity: opacity.clamp(.25, 1),
          child: const CircleAvatar(
            radius: 3,
            backgroundColor: AppColors.onPrimary,
          ),
        ),
      );
    }),
  );
}