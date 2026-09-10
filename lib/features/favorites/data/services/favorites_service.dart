// Consulta paginada de referências privadas e escrita de favorito.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/favorites_page.dart';
import '../../../station_details/data/services/station_details_service.dart';

class FavoritesService {
  FavoritesService(this.firestore, this.stations);
  final FirebaseFirestore firestore;
  final StationDetailsService stations;
  Future<FavoritesPageData> load(String uid, {String? after}) async {
    Query<Map<String, dynamic>> query = firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('stationId');
    if (after != null) query = query.startAfter([after]);
    final snapshot = await query.limit(21).get();
    final docs = snapshot.docs.take(20).toList();
    final ids = docs.map((doc) => doc.id).toList();
    final details = await stations.readExistingStations(ids);
    final byId = {for (final station in details) station.uid: station};
    return FavoritesPageData(
      stations: [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ],
      cursor: docs.isEmpty ? null : docs.last.data()['stationId'] as String,
      hasMore: snapshot.docs.length > 20,
    );
  }

  Future<void> setFavorite(
    String uid,
    String stationUid, {
    required bool favorite,
  }) => stations.setFavorite(uid, stationUid, favorite: favorite);
}
