// Composição das avaliações do painel: reaproveita o `StationDetailsService`
// (mesma coleção pública) com o uid do dono logado como quem denuncia.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../station_details/data/services/station_details_service.dart';
import '../../../station_details/domain/models/station_reviews_state.dart';
import '../../data/repositories/station_panel_reviews_repository_impl.dart';
import '../../domain/repositories/station_panel_reviews_repository.dart';
import '../viewmodels/station_panel_reviews_viewmodel.dart';

final stationPanelReviewsRepositoryProvider =
    Provider<StationPanelReviewsRepository>(
      (ref) => StationPanelReviewsRepositoryImpl(
        StationDetailsService(FirebaseFirestore.instance),
        uidProvider: () => FirebaseAuth.instance.currentUser?.uid,
      ),
    );

final stationPanelReviewsViewModelProvider =
    AsyncNotifierProvider.family<
      StationPanelReviewsViewModel,
      StationReviewsState,
      String
    >(() => StationPanelReviewsViewModel(stationPanelReviewsRepositoryProvider));
