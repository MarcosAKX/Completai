// Denúncias de avaliação vistas pelo administrador.
//
// A lista vem de `collectionGroup('reports')` — sem essa consulta o admin só
// leria uma denúncia por vez sabendo o caminho exato, ou seja, não teria como
// descobrir que existe denúncia nova. A regra de collection group nas
// `firestore.rules` concede apenas `list`, e apenas para admin.
//
// `stationUid` e `clientUid` saem do CAMINHO do documento, não de campos: a
// consulta não precisa de campo redundante nem de índice extra para saber de
// quem é a denúncia. A mesma regra alcança `station_reports/.../reports`, que
// esta tela descarta por não casar o formato do caminho.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../station_details/domain/models/station_review.dart';
import '../../../../shared/models/report_reason.dart';
import '../../domain/models/report_status.dart';
import '../../domain/models/review_report.dart';

class AdminReportsService {
  AdminReportsService(this._firestore);

  final FirebaseFirestore _firestore;


  Future<ReviewReportPage> readReportPage({
    ReviewReportCursor? after,
    int limit = 20,
  }) async {
    // Só `createdAt` + `__name__` na ordenação: `status` é filtrado em Dart
    // para não exigir índice composto. Denúncia é volume baixo.
    var query = _firestore
        .collectionGroup('reports')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);

    if (after != null) {
      query = query.startAfter([
        Timestamp(after.seconds, after.nanoseconds),
        _firestore.doc(after.documentPath),
      ]);
    }

    final snapshot = await query.limit(limit + 1).get();
    final documents = snapshot.docs;
    final hasMore = documents.length > limit;
    final page = hasMore ? documents.sublist(0, limit) : documents;

    final reports = <ReviewReport>[];
    for (final document in page) {
      final parsed = _parseReportPath(document.reference.path);
      if (parsed == null) {
        // Denúncia de posto (station_reports/...) ou caminho inesperado.
        // A regra de collectionGroup pega as duas coleções `reports`; esta
        // tela é só das de avaliação.
        continue;
      }
      reports.add(
        _mapReport(parsed.$1, parsed.$2, document.id, document.data()),
      );
    }

    // Enriquece com o nome do posto e a avaliação denunciada. Sequencial
    // por página de 20, não por item solto da lista inteira.
    final enriched = await Future.wait(reports.map(_withContext));

    final last = page.isEmpty ? null : page.last;
    final lastCreatedAt = last?.data()['createdAt'];
    return ReviewReportPage(
      reports: enriched,
      nextCursor: (hasMore && last != null && lastCreatedAt is Timestamp)
          ? ReviewReportCursor(
              seconds: lastCreatedAt.seconds,
              nanoseconds: lastCreatedAt.nanoseconds,
              documentPath: last.reference.path,
            )
          : null,
      hasMore: hasMore,
    );
  }

  /// `public_stations/{stationUid}/reviews/{clientUid}/reports/{reporterUid}`
  /// → `(stationUid, clientUid)`. `null` para qualquer outro formato.
  static (String, String)? _parseReportPath(String path) {
    final parts = path.split('/');
    if (parts.length != 6) return null;
    if (parts[0] != 'public_stations' || parts[2] != 'reviews') return null;
    if (parts[4] != 'reports') return null;
    return (parts[1], parts[3]);
  }

  ReviewReport _mapReport(
    String stationUid,
    String clientUid,
    String reporterUid,
    Map<String, dynamic> data,
  ) => ReviewReport(
    stationUid: stationUid,
    clientUid: clientUid,
    reporterUid: reporterUid,
    reason: ReportReason.fromWire(data['reason']),
    status: ReportStatus.fromWire(data['status']),
    createdAt: data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null,
  );

  Future<ReviewReport> _withContext(ReviewReport report) async {
    final results = await Future.wait([
      _firestore.collection('public_stations').doc(report.stationUid).get(),
      _firestore
          .collection('public_stations')
          .doc(report.stationUid)
          .collection('reviews')
          .doc(report.clientUid)
          .get(),
    ]);

    final stationData = results[0].data();
    final stationName = stationData?['brandName'];
    final reviewData = results[1].data();
    final review = reviewData == null
        ? null
        : _mapReview(report.clientUid, reviewData);

    // Rede de segurança para denúncias órfãs antigas: ninguém denuncia uma
    // avaliação que ainda não existia. Se a avaliação nesse caminho é mais
    // NOVA que a denúncia, é outra avaliação — a denunciada já foi removida
    // e o cliente escreveu de novo (o id do documento é o uid dele, então o
    // caminho se repete). Mostrar o texto novo sob uma denúncia velha faria
    // o admin julgar o texto errado.
    final denounced =
        review != null &&
        !(review.createdAt != null &&
            report.createdAt != null &&
            review.createdAt!.isAfter(report.createdAt!));

    return ReviewReport(
      stationUid: report.stationUid,
      clientUid: report.clientUid,
      reporterUid: report.reporterUid,
      reason: report.reason,
      status: report.status,
      createdAt: report.createdAt,
      stationName: stationName is String ? stationName : '',
      review: denounced ? review : null,
      reviewMissing: !denounced,
    );
  }

  StationReview _mapReview(String clientUid, Map<String, dynamic> data) =>
      StationReview(
        clientUid: clientUid,
        clientName: data['clientName'] is String
            ? data['clientName'] as String
            : 'Cliente',
        rating: data['rating'] is int ? data['rating'] as int : 0,
        comment: data['comment'] is String ? data['comment'] as String : '',
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
      );

  DocumentReference<Map<String, dynamic>> _reportRef(ReviewReport report) =>
      _firestore
          .collection('public_stations')
          .doc(report.stationUid)
          .collection('reviews')
          .doc(report.clientUid)
          .collection('reports')
          .doc(report.reporterUid);

  Future<void> writeReportStatus(ReviewReport report, ReportStatus status) =>
      _reportRef(report).update({'status': status.wireValue});

  /// Apaga a avaliação e recalcula os agregados do posto na mesma transação.
  ///
  /// Recalcula a partir do estado atual em vez de subtrair às cegas: se a
  /// avaliação já tinha sido removida, os agregados não entram em valor
  /// negativo. As rules aceitam a diminuição de `reviewCount` pelo caso 2 do
  /// update de `public_stations`.
  Future<void> deleteReportedReview(ReviewReport report) async {
    final stationRef = _firestore
        .collection('public_stations')
        .doc(report.stationUid);
    final reviewRef = stationRef
        .collection('reviews')
        .doc(report.clientUid);

    // O Firestore NÃO apaga subcoleção junto com o documento pai. Sem apagar
    // as denúncias penduradas na avaliação, elas sobrevivem e "grudam" na
    // próxima avaliação que o mesmo cliente escrever — o id do documento de
    // review é o uid dele, então o caminho se repete. O resultado era uma
    // denúncia resolvida exibindo o texto de uma avaliação nova.
    //
    // A consulta roda fora da transação porque transação não consulta
    // coleção. Uma denúncia que chegue nesse intervalo sobrevive; fica
    // pendente para o admin, que é o comportamento certo.
    final reports = await reviewRef.collection('reports').get();

    await _firestore.runTransaction((transaction) async {
      final reviewSnapshot = await transaction.get(reviewRef);
      final stationSnapshot = await transaction.get(stationRef);

      if (reviewSnapshot.exists) {
        final data = stationSnapshot.data() ?? const <String, dynamic>{};
        final count = data['reviewCount'];
        final average = data['averageRating'];
        final rating = reviewSnapshot.data()?['rating'];

        final currentCount = count is int && count > 0 ? count : 0;
        final currentAverage = average is num ? average.toDouble() : 0.0;
        final removedRating = rating is num ? rating.toDouble() : 0.0;

        final nextCount = currentCount > 0 ? currentCount - 1 : 0;
        final nextAverage = nextCount == 0
            ? 0.0
            : ((currentAverage * currentCount) - removedRating) / nextCount;

        transaction.delete(reviewRef);
        transaction.update(stationRef, {
          'reviewCount': nextCount,
          'averageRating': nextAverage.clamp(0, 5),
        });
        // Some com a avaliação e com tudo que pendia dela.
        for (final document in reports.docs) {
          transaction.delete(document.reference);
        }
      } else {
        // A avaliação já tinha sumido: marca a denúncia como resolvida em
        // vez de apagá-la, para o admin ver que a ação foi registrada.
        transaction.update(_reportRef(report), {
          'status': ReportStatus.resolved.wireValue,
        });
      }
    });
  }
}
