// Busca por autor no grupo reviews e lê só os postos da página.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../station_details/data/services/station_details_service.dart';
import '../../domain/models/my_review.dart';

class MyReviewsService {
  MyReviewsService(this.firestore, this.stations);
  final FirebaseFirestore firestore;
  final StationDetailsService stations;
  Future<MyReviewsPageData> load(String uid, {MyReviewsCursor? after}) async {
    Query<Map<String, dynamic>> query = firestore
        .collectionGroup('reviews')
        .where('clientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (after != null) {
      query = query.startAfter([
        Timestamp(after.seconds, after.nanoseconds),
        after.path,
      ]);
    }
    final snapshot = await query.limit(21).get();
    final docs = snapshot.docs.take(20).toList();
    // O grupo pode ter outros caminhos no futuro; só exibimos reviews de postos.
    final valid = docs.where((doc) {
      final path = doc.reference.path.split('/');
      return path.length == 4 &&
          path[0] == 'public_stations' &&
          path[2] == 'reviews' &&
          path[3] == uid;
    }).toList();
    final ids = valid
        .map((doc) => doc.reference.parent.parent!.id)
        .toSet()
        .toList();
    final publicData = await stations.readExistingStations(ids);
    final byId = {for (final station in publicData) station.uid: station};
    final last = docs.isEmpty ? null : docs.last;
    final date = last?.data()['createdAt'] as Timestamp?;
    return MyReviewsPageData(
      reviews: valid.map((doc) {
        final data = doc.data();
        final id = doc.reference.parent.parent!.id;
        return MyReview(
          stationUid: id,
          station: byId[id],
          rating: (data['rating'] as num? ?? 0).toInt().clamp(0, 5),
          comment: data['comment'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        );
      }).toList(),
      cursor: last == null || date == null
          ? null
          : MyReviewsCursor(
              seconds: date.seconds,
              nanoseconds: date.nanoseconds,
              path: last.reference.path,
            ),
      hasMore: snapshot.docs.length > 20,
    );
  }
}
