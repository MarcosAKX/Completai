// Validação defensiva e isolamento de documentos públicos antigos/malformados.
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/exceptions.dart';

const _fuelKeys = [
  'gasolineRegular',
  'gasolineAdditive',
  'ethanol',
  'dieselS10',
  'dieselS500',
];
const _days = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

void validatePublicStationData(Map<String, dynamic> data) {
  void require(bool condition) {
    if (!condition) {
      throw const ValidationException(
        'Os dados deste posto estão inconsistentes. Tente novamente mais tarde.',
      );
    }
  }

  // Ausência em documentos antigos mantém os fallbacks existentes. Tipo errado não.
  for (final key in [
    'brandName',
    'brand',
    'address',
    'neighborhood',
    'city',
    'state',
    'citySearchKey',
  ]) {
    require(data[key] == null || data[key] is String);
  }
  for (final entry in {
    'latitude': 90,
    'longitude': 180,
    'averageRating': 5,
  }.entries) {
    final value = data[entry.key];
    require(
      value == null ||
          (value is num &&
              value.isFinite &&
              value >= (entry.key == 'averageRating' ? 0 : -entry.value) &&
              value <= entry.value),
    );
  }
  final count = data['reviewCount'];
  require(count == null || (count is int && count >= 0));
  require(
    data['pricesUpdatedAt'] == null || data['pricesUpdatedAt'] is Timestamp,
  );
  for (final key in ['services', 'tags']) {
    require(data[key] == null || data[key] is List);
  }
  final prices = data['prices'];
  require(prices == null || prices is Map<String, dynamic>);
  if (prices is Map<String, dynamic>) {
    for (final key in _fuelKeys) {
      final price = prices[key];
      require(
        price == null ||
            (price is num &&
                price.isFinite &&
                price >= 0.01 &&
                price <= 99.999),
      );
    }
  }
  final hours = data['openingHours'];
  require(hours == null || hours is Map<String, dynamic>);
  if (hours is Map<String, dynamic>) {
    final time = RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$');
    for (final day in _days) {
      final period = hours[day];
      require(
        period == null ||
            (period is Map<String, dynamic> &&
                period['open'] is String &&
                period['close'] is String &&
                time.hasMatch(period['open'] as String) &&
                time.hasMatch(period['close'] as String)),
      );
    }
  }
}

List<T> mapValidPublicStations<T>(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  T Function(QueryDocumentSnapshot<Map<String, dynamic>>) map,
) {
  final values = <T>[];
  for (final document in documents) {
    try {
      validatePublicStationData(document.data());
      values.add(map(document));
    } on ValidationException catch (error) {
      // Registra só o caminho; não expõe conteúdo nem engole erros de programação.
      developer.log(
        'Posto público ignorado: ${document.reference.path}',
        name: 'public_stations',
        error: error,
      );
    }
  }
  return values;
}
