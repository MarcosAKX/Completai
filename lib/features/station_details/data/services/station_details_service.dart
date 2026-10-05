// Acesso direto aos documentos públicos, favoritos privados e avaliações.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/report_reason.dart';
import '../../../../shared/models/station_approval_status.dart';
import '../../../../shared/models/station_brand.dart';
import '../../../../shared/models/station_fuel.dart';
import '../../../../shared/services/public_station_data.dart';
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
    // Pendente ou recusado não abre para o motorista, mesmo que ele chegue
    // por favorito antigo ou pelo histórico de avaliações. Mensagem igual à
    // de posto inexistente de propósito: não cabe contar ao cliente que
    // existe um posto aguardando aprovação.
    if (!StationApprovalStatus.fromWire(data['status']).isVisibleToDrivers) {
      throw const ValidationException('Posto não encontrado.');
    }
    validatePublicStationData(data);
    return _mapStation(snapshot.id, data);
  }

  /// Lê somente os documentos públicos de uma página de favoritos.
  /// Documentos removidos são omitidos, sem consultar reviews nem imagens.
  Future<List<StationDetails>> readExistingStations(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _firestore
        .collection('public_stations')
        .where(FieldPath.documentId, whereIn: ids)
        .limit(20)
        .get();
    // Mesma regra da Home: posto não aprovado é omitido da lista.
    final visible = snapshot.docs.where(
      (doc) => StationApprovalStatus.fromWire(
        doc.data()['status'],
      ).isVisibleToDrivers,
    );
    return mapValidPublicStations(
      visible,
      (doc) => _mapStation(doc.id, doc.data()),
    );
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
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (after != null) {
      query = query.startAfter([
        Timestamp(after.seconds, after.nanoseconds),
        after.documentId,
      ]);
    }
    final snapshot = await query.limit(limit + 1).get();
    final visible = snapshot.docs.take(limit).toList(growable: false);
    final last = visible.isEmpty ? null : visible.last;
    final lastDate = last?.data()['createdAt'] as Timestamp?;
    return StationReviewPage(
      reviews: visible.map(_mapReview).toList(growable: false),
      nextCursor: last == null || lastDate == null
          ? null
          : StationReviewCursor(
              seconds: lastDate.seconds,
              nanoseconds: lastDate.nanoseconds,
              documentId: last.id,
            ),
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

      // Avaliação é única e definitiva. Antes a segunda escrita substituía a
      // primeira (o id do documento é o uid do cliente, então nunca houve
      // duplicata — mas dava para reescrever). A checagem vive dentro da
      // transação: fora dela, dois envios simultâneos passariam os dois.
      if (previous.exists) {
        throw const ValidationException(
          'Você já avaliou este posto. Cada cliente avalia uma única vez.',
        );
      }

      final oldCount = (stationData['reviewCount'] as num?)?.toInt() ?? 0;
      final oldAverage =
          (stationData['averageRating'] as num?)?.toDouble() ?? 0;
      final newCount = oldCount + 1;
      final newAverage = (oldAverage * oldCount + rating) / newCount;

      transaction.set(reviewRef, {
        'clientUid': clientUid,
        'clientName': userData?['name'] as String? ?? 'Cliente',
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(stationRef, {
        'averageRating': newAverage,
        'reviewCount': newCount,
      });
    });
  }

  /// O cliente já avaliou este posto? Uma leitura de documento por abertura
  /// do detalhe — o id da review é o uid, então não precisa de consulta.
  Future<bool> hasReviewed(String stationUid, String clientUid) async {
    final snapshot = await _firestore
        .collection('public_stations')
        .doc(stationUid)
        .collection('reviews')
        .doc(clientUid)
        .get();
    return snapshot.exists;
  }

  /// Denúncia de uma review específica, feita pelo dono do posto (ou
  /// qualquer usuário autenticado). Caminho e regras já existiam
  /// (`public_stations/{uid}/reviews/{clientUid}/reports/{reporterUid}`),
  /// só não havia código Dart que escrevesse nele.
  Future<void> reportReview({
    required String stationUid,
    required String clientUid,
    required String reporterUid,
    required String reason,
  }) async {
    // Espelha a lista fechada das rules. Sem esta checagem, um motivo fora
    // do enum chegaria no Firestore e voltaria como permission-denied, que
    // é erro ilegível para o dono do posto.
    if (!ReportReason.values.any((value) => value.wireValue == reason)) {
      throw const ValidationException('Escolha um motivo válido.');
    }
    await _firestore
        .collection('public_stations')
        .doc(stationUid)
        .collection('reviews')
        .doc(clientUid)
        .collection('reports')
        .doc(reporterUid)
        .set({
          'reporterUid': reporterUid,
          'reason': reason.trim(),
          // Sempre 'pending': redenunciar reabre a analise. As rules só
          // aceitam este valor vindo de quem denuncia — marcar a própria
          // denúncia como resolvida a esconderia do admin.
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  StationDetails _mapStation(String uid, Map<String, dynamic> data) {
    // `Map` cru, nao `Map<String, dynamic>`: o `cloud_firestore` devolve mapa
    // ANINHADO como `Map<Object?, Object?>` no aparelho real. O cast duro
    // lancava e derrubava a leitura inteira.
    final prices = data['prices'] is Map ? data['prices'] as Map : const {};
    final hours = data['openingHours'] is Map
        ? data['openingHours'] as Map
        : const {};
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
  StationOpeningPeriod? _mapPeriod(Object? value) {
    if (value is! Map) return null;
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
