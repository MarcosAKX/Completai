// Consulta apenas os dados públicos necessários à lista, com limite explícito.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/station_brand.dart';
import '../../domain/models/station_summary.dart';

class PublicStationService {
  PublicStationService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<StationSummary>> fetchByCityKey(String key) async {
    final snapshot = await _firestore
        .collection('public_stations')
        .where('citySearchKey', isEqualTo: key)
        .limit(50)
        .get();

    return snapshot.docs.map(_map).toList(growable: false);
  }

  StationSummary _map(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final prices = data['prices'] as Map<String, dynamic>? ?? const {};

    final hours = data['openingHours'] as Map<String, dynamic>? ?? const {};

    const weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final today =
        hours[weekdays[DateTime.now().weekday - 1]] as Map<String, dynamic>?;

    double? number(Object? value) {
      return value is num ? value.toDouble() : null;
    }

    return StationSummary(
      uid: doc.id,
      name: data['brandName'] as String? ?? 'Posto',
      brand: StationBrand.fromWire(data['brand']),
      neighborhood: data['neighborhood'] as String? ?? '',
      city: data['city'] as String? ?? '',
      latitude: number(data['latitude']) ?? 0,
      longitude: number(data['longitude']) ?? 0,
      prices: {
        FuelType.gasoline: number(prices['gasolineRegular']),
        FuelType.ethanol: number(prices['ethanol']),
        FuelType.diesel: number(prices['dieselS10'] ?? prices['dieselS500']),
      },
      averageRating: number(data['averageRating']) ?? 0,
      reviewCount: data['reviewCount'] is int ? data['reviewCount'] as int : 0,
      pricesUpdatedAt: (data['pricesUpdatedAt'] as Timestamp?)?.toDate(),
      todayHours: today == null
          ? null
          : DailyHours(
              open: today['open'] as String? ?? '',
              close: today['close'] as String? ?? '',
            ),
    );
  }
}
