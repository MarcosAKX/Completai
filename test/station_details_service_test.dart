// Detalhe público: mapeamento, consultas limitadas, favorito e review atômica.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:completai/features/station_details/data/services/station_details_service.dart';
import 'package:completai/features/station_details/domain/models/station_review_page.dart';
import 'package:completai/shared/models/station_fuel.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

const _stationUid = 'station-1';
const _clientUid = 'client-1';

Future<FakeFirebaseFirestore> _seeded() async {
  final firestore = FakeFirebaseFirestore();
  await firestore.collection('users').doc(_clientUid).set({
    'uid': _clientUid,
    'type': 'client',
    'name': 'Marcos',
  });
  await firestore.collection('public_stations').doc(_stationUid).set({
    'uid': _stationUid,
    'brandName': 'Posto Avenida',
    'brand': 'shell',
    'address': 'Av. Brasil, 1000',
    'neighborhood': 'Centro',
    'city': 'Bebedouro',
    'state': 'SP',
    'latitude': -20.94,
    'longitude': -48.48,
    'prices': {
      'gasolineRegular': 5.79,
      'gasolineAdditive': 5.99,
      'ethanol': 3.89,
      'dieselS10': 5.89,
      'dieselS500': 5.69,
    },
    'pricesUpdatedAt': Timestamp.fromDate(DateTime(2026, 9, 7, 9, 20)),
    'openingHours': {
      'monday': {'open': '06:00', 'close': '22:00'},
      'tuesday': {'open': '06:00', 'close': '22:00'},
      'wednesday': null,
      'thursday': null,
      'friday': null,
      'saturday': null,
      'sunday': null,
    },
    'averageRating': 4.5,
    'reviewCount': 2,
    'services': ['convenience', 'oil_change', 'tire_inflation'],
    'tags': <String>[],
  });
  await firestore
      .collection('public_stations')
      .doc(_stationUid)
      .collection('reviews')
      .doc('client-2')
      .set({
        'clientUid': 'client-2',
        'clientName': 'Ana',
        'rating': 5,
        'comment': 'Ótimo atendimento.',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 6)),
      });
  for (var index = 3; index <= 5; index++) {
    await firestore
        .collection('public_stations')
        .doc(_stationUid)
        .collection('reviews')
        .doc('client-$index')
        .set({
          'clientUid': 'client-$index',
          'clientName': 'Cliente $index',
          'rating': index == 5 ? 5 : 4,
          'comment': 'Avaliação $index',
          'createdAt': Timestamp.fromDate(DateTime(2026, 9, index)),
        });
  }
  return firestore;
}

void main() {
  for (final nanoseconds in [0, 123456789]) {
    test(
      'cursor preserva timestamp completo e documento ($nanoseconds ns)',
      () async {
        final firestore = FakeFirebaseFirestore();
        final reviews = firestore
            .collection('public_stations')
            .doc(_stationUid)
            .collection('reviews');
        for (var index = 0; index < 21; index++) {
          final uid = 'client-${index.toString().padLeft(2, '0')}';
          await reviews.doc(uid).set({
            'clientUid': uid,
            'rating': 5,
            'createdAt': Timestamp(1700000000, nanoseconds),
          });
        }
        final service = StationDetailsService(firestore);
        final first = await service.readReviewPage(_stationUid);
        expect(first.reviews, hasLength(20));
        expect(first.hasMore, isTrue);
        expect(first.nextCursor!.seconds, 1700000000);
        expect(first.nextCursor!.nanoseconds, nanoseconds);
        expect(first.nextCursor!.documentId, first.reviews.last.clientUid);
        expect(
          first.reviews.map((review) => review.clientUid),
          orderedEquals(
            List.generate(
              20,
              (index) => 'client-${(20 - index).toString().padLeft(2, '0')}',
            ),
          ),
        );
      },
    );
  }

  test('mapeia os cinco preços, serviços e horários públicos', () async {
    final service = StationDetailsService(await _seeded());

    final details = await service.readStation(_stationUid);

    expect(details.name, 'Posto Avenida');
    expect(details.priceFor(StationFuel.gasolineRegular), 5.79);
    expect(details.priceFor(StationFuel.dieselS500), 5.69);
    expect(details.services, hasLength(3));
    expect(details.openingHours, hasLength(7));
    expect(details.openingHours['monday']?.close, '22:00');
  });

  test('lê prévia limitada de avaliações', () async {
    final service = StationDetailsService(await _seeded());

    final reviews = await service.readReviews(_stationUid, limit: 1);

    expect(reviews, hasLength(1));
    expect(reviews.single.clientName, 'Ana');
  });

  // O fake não implementa startAfter com FieldPath.documentId.
  // A continuação real é exercitada no Firebase Emulator (tests/firestore-rules).
  test('primeira página informa continuação e cursor', () async {
    final service = StationDetailsService(await _seeded());

    final first = await service.readReviewPage(_stationUid, limit: 2);

    expect(first.reviews, hasLength(2));
    expect(first.hasMore, isTrue);
    expect(first.nextCursor, isA<StationReviewCursor>());
  });

  test('alterna favorito no documento privado do cliente', () async {
    final firestore = await _seeded();
    final service = StationDetailsService(firestore);

    expect(await service.isFavorite(_clientUid, _stationUid), isFalse);
    await service.setFavorite(_clientUid, _stationUid, favorite: true);
    expect(await service.isFavorite(_clientUid, _stationUid), isTrue);
    await service.setFavorite(_clientUid, _stationUid, favorite: false);
    expect(await service.isFavorite(_clientUid, _stationUid), isFalse);
  });

  test('cria review e atualiza agregados na mesma transação', () async {
    final firestore = await _seeded();
    final service = StationDetailsService(firestore);

    await service.writeReview(
      stationUid: _stationUid,
      clientUid: _clientUid,
      rating: 5,
      comment: 'Muito bom.',
    );

    final station =
        (await firestore.collection('public_stations').doc(_stationUid).get())
            .data()!;
    final review =
        (await firestore
                .collection('public_stations')
                .doc(_stationUid)
                .collection('reviews')
                .doc(_clientUid)
                .get())
            .data()!;
    expect(station['reviewCount'], 3);
    expect(station['averageRating'], closeTo(14 / 3, 0.001));
    expect(review['clientName'], 'Marcos');
    expect(review['rating'], 5);
  });
}
