// Services de admin contra FakeFirebaseFirestore: fila, aprovação,
// denúncias e remoção de avaliação com recálculo de nota.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:completai/features/admin/data/services/admin_reports_service.dart';
import 'package:completai/features/admin/data/services/admin_stations_service.dart';
import 'package:completai/features/admin/domain/models/report_status.dart';
import 'package:completai/shared/models/report_reason.dart';
import 'package:completai/shared/models/station_approval_status.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _public({
  String name = 'Posto Teste',
  String? status = 'pending',
}) => {
  'brandName': name,
  'address': 'Rua Um, 100',
  'neighborhood': 'Centro',
  'city': 'Bebedouro',
  'citySearchKey': 'bebedouro',
  'state': 'SP',
  'cep': '14700000',
  'latitude': -20.9,
  'longitude': -48.4,
  'prices': {
    'gasolineRegular': null,
    'gasolineAdditive': null,
    'ethanol': null,
    'dieselS10': null,
    'dieselS500': null,
  },
  'openingHours': const {'monday': null},
  'averageRating': 0.0,
  'reviewCount': 0,
  'services': <String>[],
  'tags': <String>[],
  'status': ?status,
};

Map<String, dynamic> _private(String uid) => {
  'uid': uid,
  'type': 'gas_station',
  'cnpj': '12345678000190',
  'email': 'posto@example.test',
  'phone': '(17) 3333-4444',
  'brandName': 'Posto Teste',
  'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
};

void main() {
  group('AdminStationsService', () {
    test('separa pendentes de listados e junta o dado privado', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('public_stations')
          .doc('p1')
          .set(_public(name: 'Pendente'));
      await firestore.collection('gas_stations').doc('p1').set(_private('p1'));
      await firestore
          .collection('public_stations')
          .doc('p2')
          .set(_public(name: 'Aprovado', status: 'approved'));
      await firestore.collection('gas_stations').doc('p2').set(_private('p2'));

      final state = await AdminStationsService(firestore).readStations();

      expect(state.pending, hasLength(1));
      expect(state.pending.single.name, 'Pendente');
      expect(state.pending.single.cnpj, '12345678000190');
      expect(state.pending.single.cnpjFormatted, '12.345.678/0001-90');
      expect(state.pending.single.cepFormatted, '14700-000');
      expect(state.listed, hasLength(1));
      expect(state.listed.single.name, 'Aprovado');
    });

    test('posto legado sem status entra como listado, nao na fila', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('public_stations')
          .doc('antigo')
          .set(_public(name: 'Antigo', status: null));

      final state = await AdminStationsService(firestore).readStations();

      expect(state.pending, isEmpty);
      expect(state.listed.single.status, StationApprovalStatus.approved);
    });

    test('posto sem documento privado aparece marcado, nao desaparece', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('public_stations').doc('orfao').set(_public());

      final state = await AdminStationsService(firestore).readStations();

      expect(state.pending.single.privateDataMissing, isTrue);
      expect(state.pending.single.cnpjFormatted, '—');
    });

    test('documento malformado e isolado e registrado, nao derruba a fila', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('public_stations').doc('ok').set(_public());
      await firestore
          .collection('public_stations')
          .doc('ruim')
          .set({..._public(), 'latitude': 'muito ao norte'});

      final state = await AdminStationsService(firestore).readStations();

      expect(state.pending, hasLength(1));
      expect(state.invalidDocumentPaths, ['public_stations/ruim']);
    });

    test('aprovar grava somente o status', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('public_stations').doc('p1').set(_public());

      await AdminStationsService(
        firestore,
      ).writeStationStatus('p1', StationApprovalStatus.approved);

      final data = (await firestore
              .collection('public_stations')
              .doc('p1')
              .get())
          .data()!;
      expect(data['status'], 'approved');
      expect(data['brandName'], 'Posto Teste');
    });
  });

  group('AdminReportsService', () {
    Future<FakeFirebaseFirestore> seeded() async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('public_stations').doc('p1').set({
        ..._public(name: 'Posto Um'),
        'averageRating': 4.0,
        'reviewCount': 2,
      });
      await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .set({
            'clientUid': 'bob',
            'clientName': 'Bob',
            'rating': 3,
            'comment': 'Comentario denunciado',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
          });
      await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .collection('reports')
          .doc('p1')
          .set({
            'reporterUid': 'p1',
            'reason': 'offensive',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000001000),
          });
      return firestore;
    }

    test('le a denuncia com posto e avaliacao anexados', () async {
      final page = await AdminReportsService(await seeded()).readReportPage();

      expect(page.reports, hasLength(1));
      final report = page.reports.single;
      // stationUid e clientUid vêm do caminho, não de campos do documento.
      expect(report.stationUid, 'p1');
      expect(report.clientUid, 'bob');
      expect(report.reporterUid, 'p1');
      expect(report.reason, ReportReason.offensive);
      expect(report.status, ReportStatus.pending);
      expect(report.stationName, 'Posto Um');
      expect(report.review?.comment, 'Comentario denunciado');
      expect(report.canRemoveReview, isTrue);
      expect(report.id, 'p1/bob/p1');
    });

    test('denuncia de posto nao entra nesta tela', () async {
      final firestore = await seeded();
      await firestore
          .collection('station_reports')
          .doc('p1')
          .collection('reports')
          .doc('alice')
          .set({
            'reporterUid': 'alice',
            'reason': 'fake',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000002000),
          });

      final page = await AdminReportsService(firestore).readReportPage();

      // O collectionGroup traz as duas coleções `reports`; o formato do
      // caminho é o que separa.
      expect(page.reports, hasLength(1));
      expect(page.reports.single.clientUid, 'bob');
    });

    test('denuncia sem avaliacao vira reviewMissing sem quebrar a lista', () async {
      final firestore = await seeded();
      // Denuncia apontando para uma avaliacao que nao existe. Nao uso
      // `delete()` na avaliacao porque o FakeFirebaseFirestore remove a
      // subcolecao junto com o documento pai — o Firestore real preserva,
      // e e justamente o caso de denuncia orfa que queremos cobrir.
      await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('carol')
          .collection('reports')
          .doc('p1')
          .set({
            'reporterUid': 'p1',
            'reason': 'fake',
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000003000),
          });

      final page = await AdminReportsService(firestore).readReportPage();
      final orfa = page.reports.firstWhere((r) => r.clientUid == 'carol');

      expect(orfa.reviewMissing, isTrue);
      expect(orfa.review, isNull);
      expect(orfa.canRemoveReview, isFalse);
      // A denuncia com avaliacao existente continua intacta na mesma pagina.
      expect(page.reports.any((r) => r.canRemoveReview), isTrue);
    });

    test('descartar marca a denuncia e preserva a avaliacao', () async {
      final firestore = await seeded();
      final service = AdminReportsService(firestore);
      final report = (await service.readReportPage()).reports.single;

      await service.writeReportStatus(report, ReportStatus.dismissed);

      final data = (await firestore
              .collection('public_stations')
              .doc('p1')
              .collection('reviews')
              .doc('bob')
              .collection('reports')
              .doc('p1')
              .get())
          .data()!;
      expect(data['status'], 'dismissed');

      final review = await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .get();
      expect(review.exists, isTrue);
    });

    test('remover apaga a avaliacao e recalcula a nota', () async {
      final firestore = await seeded();
      final service = AdminReportsService(firestore);
      final report = (await service.readReportPage()).reports.single;

      await service.deleteReportedReview(report);

      final review = await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .get();
      expect(review.exists, isFalse);

      final station = (await firestore
              .collection('public_stations')
              .doc('p1')
              .get())
          .data()!;
      // Media 4.0 com 2 avaliacoes, removendo uma de nota 3: (8-3)/1 = 5.
      expect(station['reviewCount'], 1);
      expect(station['averageRating'], closeTo(5.0, 1e-9));

      // A denuncia e APAGADA junto com a avaliacao, nao marcada como
      // resolvida: deixada para tras, ela grudaria na proxima avaliacao do
      // mesmo cliente, que cai no mesmo caminho.
      final reportDoc = await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .collection('reports')
          .doc('p1')
          .get();
      expect(reportDoc.exists, isFalse);
    });

    test('avaliacao ja ausente: denuncia e marcada resolvida, nao apagada', () async {
      final firestore = await seeded();
      final service = AdminReportsService(firestore);
      final report = (await service.readReportPage()).reports.single;
      // Simula a avaliacao removida por outro caminho (o proprio autor).
      await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .set({'clientUid': 'bob'});
      await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .delete();

      await service.deleteReportedReview(report);

      // Sem avaliacao para apagar, o registro da analise permanece.
      final reportDoc = await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .collection('reports')
          .doc('p1')
          .get();
      expect(reportDoc.data()?['status'], 'resolved');
    });

    test('remover apaga tambem as denuncias penduradas na avaliacao', () async {
      final firestore = await seeded();
      final service = AdminReportsService(firestore);
      final report = (await service.readReportPage()).reports.single;

      await service.deleteReportedReview(report);

      // O Firestore nao apaga subcolecao junto com o pai. Se a denuncia
      // sobrevivesse, ela grudaria na proxima avaliacao do mesmo cliente,
      // que cai no mesmo caminho.
      final restantes = await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .collection('reports')
          .get();
      expect(restantes.docs, isEmpty);
    });

    test('denuncia orfa nao exibe avaliacao mais nova que ela', () async {
      final firestore = await seeded();
      // Denuncia de 01/01, avaliacao de 02/01: ninguem denuncia o que ainda
      // nao existe, entao esta avaliacao nao e a denunciada.
      await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .collection('reports')
          .doc('p1')
          .update({
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
          });
      await firestore
          .collection('public_stations')
          .doc('p1')
          .collection('reviews')
          .doc('bob')
          .update({
            'createdAt': Timestamp.fromMillisecondsSinceEpoch(1800000000000),
          });

      final report = (await AdminReportsService(
        firestore,
      ).readReportPage()).reports.single;

      expect(report.review, isNull);
      expect(report.reviewMissing, isTrue);
      expect(report.canRemoveReview, isFalse);
    });

    test('remover a ultima avaliacao zera a nota, sem divisao por zero', () async {
      final firestore = await seeded();
      await firestore.collection('public_stations').doc('p1').update({
        'averageRating': 3.0,
        'reviewCount': 1,
      });
      final service = AdminReportsService(firestore);
      final report = (await service.readReportPage()).reports.single;

      await service.deleteReportedReview(report);

      final station = (await firestore
              .collection('public_stations')
              .doc('p1')
              .get())
          .data()!;
      expect(station['reviewCount'], 0);
      expect(station['averageRating'], 0.0);
    });
  });
}
