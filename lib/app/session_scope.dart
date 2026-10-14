// Descarta tudo que pertence à conta logada quando a conta muda.
//
// Por que isto existe: os providers de Repository e de ViewModel não são
// `autoDispose`, e vários guardam cache em memória — o perfil do posto, o
// favorito e o "já avaliei" de um detalhe, a fila do admin. Nada disso é
// apagado no logout por conta própria, então ao entrar com OUTRA conta a
// tela abria com os dados da anterior até alguém puxar para atualizar.
//
// Os repositories também passaram a guardar o uid junto do cache, de forma
// que uma conta nunca leia o cache de outra mesmo que este reset falhe. Uma
// coisa não substitui a outra: o reset limpa o estado que já está na
// ViewModel, a chave por uid protege a leitura.
//
// Ao criar um provider novo que guarde dado de uma conta, acrescente-o aqui.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/admin/presentation/providers/admin_providers.dart';
import '../features/client_profile/presentation/providers/client_profile_providers.dart';
import '../features/favorites/presentation/providers/favorites_providers.dart';
import '../features/my_reviews/presentation/providers/my_reviews_providers.dart';
import '../features/station_details/presentation/providers/station_details_providers.dart';
import '../features/station_discovery/presentation/providers/station_discovery_providers.dart';
import '../features/station_panel/presentation/providers/station_panel_providers.dart';

/// Invalida o que é da conta. Chamado pelo `AuthGate` quando o uid muda —
/// login, logout ou troca de conta.
///
/// Não toca em `sessionViewModelProvider`: é ele que dispara este reset, e
/// invalidá-lo aqui causaria um ciclo.
void resetUserScopedProviders(WidgetRef ref) {
  // Repositories primeiro: é onde moram os caches em memória. Invalidar a
  // ViewModel antes deixaria ela recarregar do cache velho.
  for (final ProviderOrFamily provider in <ProviderOrFamily>[
    adminRepositoryProvider,
    clientProfileRepositoryProvider,
    favoritesRepositoryProvider,
    myReviewsRepositoryProvider,
    stationDetailsRepositoryProvider,
    stationDiscoveryRepositoryProvider,
    stationPanelRepositoryProvider,
  ]) {
    ref.invalidate(provider);
  }

  for (final ProviderOrFamily provider in <ProviderOrFamily>[
    adminStationsViewModelProvider,
    adminReportsViewModelProvider,
    favoritesViewModelProvider,
    myReviewsViewModelProvider,
    stationDiscoveryViewModelProvider,
    stationPanelViewModelProvider,
  ]) {
    ref.invalidate(provider);
  }

  // Famílias: invalidar a família inteira alcança todas as instâncias
  // (um detalhe por posto, um perfil por uid).
  ref.invalidate(clientProfileViewModelProvider);
  ref.invalidate(stationDetailsViewModelProvider);
  ref.invalidate(stationReviewsViewModelProvider);
}
