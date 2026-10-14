// Fila de aprovação: posto novo entra aqui até o admin decidir.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/admin_station.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_station_card.dart';

class AdminPendingTab extends ConsumerStatefulWidget {
  const AdminPendingTab({super.key});

  @override
  ConsumerState<AdminPendingTab> createState() => _AdminPendingTabState();
}

class _AdminPendingTabState extends ConsumerState<AdminPendingTab> {
  /// uid em escrita, para desabilitar só os botões daquele card.
  String? _busyUid;

  Future<void> _decide(
    AdminStation station, {
    required bool approve,
  }) async {
    if (approve == false) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Recusar este posto?'),
          content: Text(
            '${station.name} não vai aparecer para os motoristas. '
            'Você pode aprovar depois, pela aba Postos listados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Recusar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _busyUid = station.uid);
    final notifier = ref.read(adminStationsViewModelProvider.notifier);
    final error = approve
        ? await notifier.approve(station.uid)
        : await notifier.reject(station.uid);
    if (!mounted) return;
    setState(() => _busyUid = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (approve
                  ? '${station.name} aprovado e já visível para os motoristas.'
                  : '${station.name} recusado.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminStationsViewModelProvider);
    final notifier = ref.read(adminStationsViewModelProvider.notifier);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AdminErrorState(
        message: error.toString(),
        onRetry: notifier.refresh,
      ),
      data: (data) => RefreshIndicator(
        onRefresh: notifier.refresh,
        child: data.pending.isEmpty
            ? const _EmptyQueue()
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: data.pending.length,
                itemBuilder: (_, index) {
                  final station = data.pending[index];
                  return AdminStationCard(
                    station: station,
                    busy: _busyUid == station.uid,
                    onApprove: () => _decide(station, approve: true),
                    onReject: () => _decide(station, approve: false),
                  );
                },
              ),
      ),
    );
  }
}

/// Lista vazia dentro de RefreshIndicator precisa rolar, senão o gesto de
/// atualizar não funciona.
class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) => ListView(
    children: const [
      SizedBox(height: 120),
      AdminEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nenhum posto esperando',
        message:
            'Quando um posto novo se cadastrar, ele aparece aqui para você '
            'conferir os dados antes de liberar.',
      ),
    ],
  );
}
