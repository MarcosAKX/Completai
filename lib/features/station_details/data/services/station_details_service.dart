// Acesso direto aos documentos públicos, favoritos privados e avaliações.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/station_brand.dart';
import '../../../../shared/models/station_fuel.dart';
import '../../domain/models/station_details.dart';
import '../../domain/models/station_review.dart';
import '../../domain/models/station_review_page.dart';

class StationDetailsService {
  StationDetailsService(this._firestore);

  final FirebaseFirestore _firestore;

  static const weekdayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  Future<StationDetails> readStation(String stationUid) async {
    final snapshot = await _firestore
        .collection('public_stations')
        .doc(stationUid)
        .get();
    final data = snapshot.data();
    if (data == null) {
      throw const ValidationException('Posto não encontrado.');
    }
    return _mapStation(snapshot.id, data);
  }

  Future<List<StationReview>> readReviews(
    String stationUid, {
    int limit = 2,
  }) async {
    return (await readReviewPage(stationUid, limit: limit)).reviews;
  }

  Future<StationReviewPage> readReviewPage(
    String stationUid, {
    StationReviewCursor? after,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('public_stations')
        .doc(stationUid)
        .collection('reviews')
        .orderBy('createdAt', descending: true);
    if (after != null) {
      query = query.where(
        'createdAt',
        isLessThan: Timestamp.fromDate(after.createdAt),
      );
    }
    final snapshot = await query.limit(limit + 1).get();
    final visible = snapshot.docs.take(limit).toList(growable: false);
    final last = visible.isEmpty ? null : visible.last;
    final lastDate = last?.data()['createdAt'] as Timestamp?;
    return StationReviewPage(
      reviews: visible.map(_mapReview).toList(growable: false),
      nextCursor: last == null || lastDate == null
          ? null
          : StationReviewCursor(createdAt: lastDate.toDate()),
      hasMore: snapshot.docs.length > limit,
    );
  }

  Future<bool> isFavorite(String clientUid, String stationUid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(clientUid)
        .collection('favorites')
        .doc(stationUid)
        .get();
    return snapshot.exists;
  }

  Future<void> setFavorite(
    String clientUid,
    String stationUid, {
    required bool favorite,
  }) async {
    final reference = _firestore
        .collection('users')
        .doc(clientUid)
        .collection('favorites')
        .doc(stationUid);
    if (favorite) {
      await reference.set({
        'stationId': stationUid,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await reference.delete();
    }
  }

  Future<void> writeReview({
    required String stationUid,
    required String clientUid,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const ValidationException('Escolha uma nota de 1 a 5.');
    }
    if (comment.trim().length > 500) {
      throw const ValidationException(
        'O comentário deve ter até 500 caracteres.',
      );
    }
    final stationRef = _firestore.collection('public_stations').doc(stationUid);
    final userRef = _firestore.collection('users').doc(clientUid);
    final reviewRef = stationRef.collection('reviews').doc(clientUid);

    await _firestore.runTransaction((transaction) async {
      final station = await transaction.get(stationRef);
      final user = await transaction.get(userRef);
      final previous = await transaction.get(reviewRef);
      final stationData = station.data();
      final userData = user.data();
      if (stationData == null) {
        throw const ValidationException('Posto não encontrado.');
      }
      if (userData?['type'] != 'client') {
        throw const UnauthenticatedException();
      }

      final oldCount = (stationData['reviewCount'] as num?)?.toInt() ?? 0;
      final oldAverage =
          (stationData['averageRating'] as num?)?.toDouble() ?? 0;
      final oldRating = (previous.data()?['rating'] as num?)?.toDouble();
      final newCount = oldRating == null ? oldCount + 1 : oldCount;
      final total = oldAverage * oldCount - (oldRating ?? 0) + rating;
      final newAverage = newCount == 0 ? 0.0 : total / newCount;

      transaction.set(reviewRef, {
        'clientUid': clientUid,
        'clientName': userData?['name'] as String? ?? 'Cliente',
        'rating': rating,
        'comment': comment.trim(),
        'createdAt':
            previous.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      transaction.update(stationRef, {
        'averageRating': newAverage,
        'reviewCount': newCount,
      });
    });
  }

  StationDetails _mapStation(String uid, Map<String, dynamic> data) {
    final prices = data['prices'] as Map<String, dynamic>? ?? const {};
    final hours = data['openingHours'] as Map<String, dynamic>? ?? const {};
    double? number(Object? value) => value is num ? value.toDouble() : null;

    return StationDetails(
      uid: uid,
      name: data['brandName'] as String? ?? 'Posto',
      brand: StationBrand.fromWire(data['brand']),
      address: data['address'] as String? ?? '',
      neighborhood: data['neighborhood'] as String? ?? '',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      latitude: number(data['latitude']) ?? 0,
      longitude: number(data['longitude']) ?? 0,
      prices: {
        for (final fuel in StationFuel.values)
          fuel: number(prices[fuel.wireKey]),
      },
      pricesUpdatedAt: (data['pricesUpdatedAt'] as Timestamp?)?.toDate(),
      openingHours: {
        for (final day in weekdayKeys) day: _mapPeriod(hours[day]),
      },
      averageRating: number(data['averageRating']) ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      services: List<String>.unmodifiable(
        (data['services'] as List<dynamic>? ?? const []).whereType<String>(),
      ),
    );
  }

  StationOpeningPeriod? _mapPeriod(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final open = value['open'];
    final close = value['close'];
    if (open is! String || close is! String) return null;
    return StationOpeningPeriod(open: open, close: close);
  }

  StationReview _mapReview(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return StationReview(
      clientUid: data['clientUid'] as String? ?? snapshot.id,
      clientName: data['clientName'] as String? ?? 'Cliente',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
