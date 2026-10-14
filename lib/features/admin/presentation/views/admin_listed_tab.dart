// Postos já revisados. Recusado pode ser reaberto; aprovado pode ser tirado
// do ar — é a única forma de corrigir uma decisão sem mexer no banco.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/station_approval_status.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_station_card.dart';

class AdminListedTab extends ConsumerStatefulWidget {
  const AdminListedTab({super.key});

  @override
  ConsumerState<AdminListedTab> createState() => _AdminListedTabState();
}

class _AdminListedTabState extends ConsumerState<AdminListedTab> {
  String? _busyUid;

  Future<void> _setStatus(String uid, String name, bool approve) async {
    setState(() => _busyUid = uid);
    final notifier = ref.read(adminStationsViewModelProvider.notifier);
    final error = approve
        ? await notifier.approve(uid)
        : await notifier.reject(uid);
    if (!mounted) return;
    setState(() => _busyUid = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (approve ? '$name voltou para a listagem.' : '$name saiu da listagem.'),
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
        child: data.listed.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  AdminEmptyState(
                    icon: Icons.local_gas_station_outlined,
                    title: 'Nenhum posto listado',
                    message:
                        'Os postos aprovados ou recusados aparecem aqui depois '
                        'que você decidir na aba Pendentes.',
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: data.listed.length + 1,
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        '${data.listed.length} '
                        '${data.listed.length == 1 ? 'posto revisado' : 'postos revisados'}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  final station = data.listed[index - 1];
                  final isApproved =
                      station.status == StationApprovalStatus.approved;
                  return AdminStationCard(
                    station: station,
                    busy: _busyUid == station.uid,
                    // Oferece só a ação contrária à situação atual.
                    onApprove: isApproved
                        ? null
                        : () => _setStatus(station.uid, station.name, true),
                    onReject: isApproved
                        ? () => _setStatus(station.uid, station.name, false)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}
