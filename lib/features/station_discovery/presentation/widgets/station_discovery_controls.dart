// Controles principais da Home:
// ações rápidas, busca e seleção de combustível.
part of '../views/station_discovery_page.dart';

const _homeBorderColor = Color(0xFFE4E9F4);

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stationDiscoveryViewModelProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.tune_rounded,
                title: 'Filtros',
                subtitle: 'Refine sua busca',
                badgeCount: state?.activeFilterCount ?? 0,
                onTap: state == null
                    ? null
                    : () => _filters(context, ref, state),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _QuickActionCard(
                icon: Icons.rate_review_outlined,
                title: 'Minhas avaliações',
                subtitle: 'Os postos que você avaliou',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.myReviews),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _QuickActionCard(
                icon: Icons.star_border_rounded,
                title: 'Postos favoritos',
                subtitle: 'Seus postos salvos',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.favorites),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeCount = 0,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 145),
          padding: const EdgeInsets.fromLTRB(10, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _homeBorderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 25),

                  const Spacer(),

                  if (badgeCount > 0)
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),
              const SizedBox(height: 9),

              const Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSearch extends ConsumerWidget {
  const _HomeSearch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: TextField(
        onChanged: ref
            .read(stationDiscoveryViewModelProvider.notifier)
            .setSearch,
        decoration: InputDecoration(
          hintText: 'Buscar posto ou bairro',
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Colors.white,
          border: _searchBorder(),
          enabledBorder: _searchBorder(),
          focusedBorder: _searchBorder(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

OutlineInputBorder _searchBorder({
  Color color = _homeBorderColor,
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.state});

  final StationDiscoveryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(stationDiscoveryViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _homeBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.local_gas_station_outlined,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Meu combustível',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 14),

            StationFuelSelector(
              selected: state.fuel,
              onSelected: vm.selectFuel,
            ),
          ],
        ),
      ),
    );
  }
}
