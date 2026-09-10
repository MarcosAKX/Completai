// Injeção da feature; cache descartado ao encerrar a tela.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../data/services/favorites_service.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/models/favorites_state.dart';
import '../viewmodels/favorites_viewmodel.dart';
import '../../../station_details/data/services/station_details_service.dart';

final favoritesRepositoryProvider = Provider.autoDispose<FavoritesRepository>(
  (ref) => FavoritesRepositoryImpl(
    FavoritesService(
      FirebaseFirestore.instance,
      StationDetailsService(FirebaseFirestore.instance),
    ),
  ),
);
final favoritesViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<FavoritesViewModel, FavoritesState, String>(
      () => FavoritesViewModel(favoritesRepositoryProvider),
    );
