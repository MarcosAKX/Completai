// Consulta apenas os dados públicos necessários à lista, com limite explícito.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/models/station_approval_status.dart';
import '../../../../shared/models/station_brand.dart';
import '../../../../shared/models/station_hours_status.dart';
import '../../../../shared/models/station_opening_period.dart';
import '../../../../shared/services/public_station_data.dart';
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

    // Posto pendente ou recusado não aparece para o motorista. O filtro é
    // em Dart, não na query: documento anterior ao campo `status` não tem o
    // campo, e um `where('status','==','approved')` simplesmente não o
    // traria — todos os postos já cadastrados desapareceriam. Ausente =
    // aprovado, ver `StationApprovalStatus.fromWire`.
    final visible = snapshot.docs.where(
      (document) => StationApprovalStatus.fromWire(
        document.data()['status'],
      ).isVisibleToDrivers,
    );
    return mapValidPublicStations(visible, _map);
  }

  StationSummary _map(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    // `Map` cru, nao `Map<String, dynamic>`: o `cloud_firestore` devolve mapa
    // ANINHADO como `Map<Object?, Object?>` no aparelho real. O cast duro
    // lancava e derrubava a leitura inteira.
    final prices = data['prices'] is Map ? data['prices'] as Map : const {};

    final hours = data['openingHours'] is Map
        ? data['openingHours'] as Map
        : const {};

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
      openingHours: Map.unmodifiable({
        for (final day in stationWeekdayKeys) day: _period(hours[day]),
      }),
    );
  }

  /// Aceita `Map` de qualquer parametrizacao, nao so `Map<String, dynamic>`.
  ///
  /// O `cloud_firestore` devolve mapa ANINHADO como `Map<Object?, Object?>`
  /// em aparelho real — o tipo se perde ao atravessar o canal de plataforma,
  /// mesmo com o documento de nivel superior tipado. Com a checagem estrita
  /// todo dia virava `null` e o posto aparecia fechado com o horario certo
  /// gravado. O `FakeFirebaseFirestore` devolve `Map<String, dynamic>`
  /// limpo, entao o teste nao pegava: por isso existe um caso com
  /// `Map<Object?, Object?>` explicito em test/station_hours_roundtrip_test.
  ///
  /// `DayHours.fromWire`, do painel, sempre foi tolerante — era essa
  /// assimetria que fazia a previa do dono divergir da tela do cliente.
  StationOpeningPeriod? _period(Object? value) {
    if (value is! Map) return null;
    final open = value['open'];
    final close = value['close'];
    if (open is! String || close is! String) return null;
    return StationOpeningPeriod(open: open, close: close);
  }
}
