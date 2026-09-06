// Composição do painel do posto: um provider por repository, uid do dono
// resolvido do Firebase Auth, tudo substituível em teste.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/address_geocoding_provider.dart';
import '../../data/repositories/station_panel_repository_impl.dart';
import '../../data/services/station_panel_service.dart';
import '../../domain/models/station_profile.dart';
import '../../domain/repositories/station_panel_repository.dart';
import '../viewmodels/station_panel_viewmodel.dart';

final stationPanelRepositoryProvider = Provider<StationPanelRepository>(
  (ref) => StationPanelRepositoryImpl(
    StationPanelService(
      FirebaseFirestore.instance,
      ref.watch(addressGeocodingServiceProvider),
    ),
    uid: () => FirebaseAuth.instance.currentUser?.uid,
  ),
);

final stationPanelViewModelProvider =
    AsyncNotifierProvider<StationPanelViewModel, StationProfile>(
      () => StationPanelViewModel(stationPanelRepositoryProvider),
    );
