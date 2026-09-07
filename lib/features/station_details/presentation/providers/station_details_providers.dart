// Composition root: um provider para o Repository e um ViewModel por posto.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/station_details_repository_impl.dart';
import '../../data/services/station_details_service.dart';
import '../../data/services/station_directions_service.dart';
import '../../domain/models/station_details_state.dart';
import '../../domain/models/station_reviews_state.dart';
import '../../domain/repositories/station_details_repository.dart';
import '../viewmodels/station_details_viewmodel.dart';
import '../viewmodels/station_reviews_viewmodel.dart';

final stationDetailsRepositoryProvider = Provider<StationDetailsRepository>(
  (ref) => StationDetailsRepositoryImpl(
    StationDetailsService(FirebaseFirestore.instance),
    const StationDirectionsService(),
    uidProvider: () => FirebaseAuth.instance.currentUser?.uid,
  ),
);

final stationDetailsViewModelProvider =
    AsyncNotifierProvider.family<
      StationDetailsViewModel,
      StationDetailsState,
      String
    >(() => StationDetailsViewModel(stationDetailsRepositoryProvider));

final stationReviewsViewModelProvider =
    AsyncNotifierProvider.family<
      StationReviewsViewModel,
      StationReviewsState,
      String
    >(() => StationReviewsViewModel(stationDetailsRepositoryProvider));
