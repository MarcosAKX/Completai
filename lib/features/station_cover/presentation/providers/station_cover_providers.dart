// Composição da feature de foto do posto, consumida pela listagem do
// motorista (`station_discovery`) e pelo painel do dono (`station_panel`).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/station_cover_repository_impl.dart';
import '../../data/services/station_cover_service.dart';
import '../../domain/models/station_cover.dart';
import '../../domain/repositories/station_cover_repository.dart';

final stationCoverRepositoryProvider = Provider<StationCoverRepository>(
  (ref) => StationCoverRepositoryImpl(
    StationCoverService(FirebaseFirestore.instance),
  ),
);

/// Foto de um posto, resolvida sob demanda e memoizada por uid enquanto a
/// tela que a usa estiver montada. `null` = posto sem foto.
final stationCoverProvider = FutureProvider.autoDispose
    .family<StationCover?, String>(
      (ref, stationUid) {
        ref.keepAlive();
        return ref.watch(stationCoverRepositoryProvider).load(stationUid);
      },
    );
