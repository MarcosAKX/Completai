// Puxar para atualizar nas abas de edição do painel do posto.
//
// As abas Preços, Informações e Horários guardam o que o dono digitou em
// estado local. Recarregar do servidor por cima disso apagaria a edição sem
// avisar — então, quando existe alteração não salva, o gesto NÃO recarrega:
// mostra o aviso e devolve o controle. Depois de recarregar de verdade, a
// aba precisa re-semear seu estado local, senão o `_dirty` dela passa a
// comparar o que estava na tela com um perfil novo e acusa alteração que
// ninguém fez.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/station_panel_providers.dart';

class PanelRefresh extends ConsumerWidget {
  const PanelRefresh({
    super.key,
    required this.child,
    required this.hasUnsavedChanges,
    required this.onReloaded,
  });

  /// A lista da aba. Precisa rolar, senão o gesto não dispara.
  final Widget child;

  /// Avaliado na hora do gesto, não na construção: o estado muda enquanto a
  /// tela está montada.
  final bool Function() hasUnsavedChanges;

  /// Re-semeia o estado local a partir do perfil recém-carregado.
  final VoidCallback onReloaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () async {
      final messenger = ScaffoldMessenger.of(context);
      if (hasUnsavedChanges()) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Salve ou desfaça as alterações antes de atualizar.',
            ),
          ),
        );
        return;
      }
      await ref.read(stationPanelViewModelProvider.notifier).reload();
      onReloaded();
    },
    child: child,
  );
}
