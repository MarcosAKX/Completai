// Fila de aprovação de postos: leitura combinada e escrita do `status`.
//
// A fila lê `public_stations` inteira (sem filtro de cidade) e separa
// pendentes/listados em Dart. Filtrar por `status` no servidor exigiria
// índice composto e um backfill em todo documento antigo — e documento
// antigo não tem o campo, então a query simplesmente não o traria.
// Ver SCHEMA-FIRESTORE.md.
//
// Junta cada posto com `gas_stations/{uid}` (CNPJ/e-mail/telefone), que o
// admin passou a poder ler de propósito — ver ADMIN.md.
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/station_brand.dart';
import '../../../../shared/services/public_station_data.dart';
import '../../domain/models/admin_station.dart';
import '../../domain/models/admin_stations_state.dart';
import '../../../../shared/models/station_approval_status.dart';

class AdminStationsService {
  AdminStationsService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Teto de postos lidos de uma vez. O MVP atende uma cidade; se um dia
  /// passar disso, a fila precisa de paginação própria.
  static const stationsLimit = 200;

  Future<AdminStationsState> readStations() async {
    final snapshot = await _firestore
        .collection('public_stations')
        .limit(stationsLimit)
        .get();

    final invalid = <String>[];
    final valid = <(String uid, Map<String, dynamic> data)>[];
    for (final document in snapshot.docs) {
      try {
        validatePublicStationData(document.data());
        valid.add((document.id, document.data()));
      } on ValidationException catch (error) {
        invalid.add(document.reference.path);
        developer.log(
          'Posto ignorado na fila de admin: ${document.reference.path}',
          name: 'admin',
          error: error,
        );
      }
    }

    // Uma leitura privada por posto. Aceitável porque é tela de admin, usada
    // por uma pessoa, e o MVP tem poucos postos — não é a Home.
    final privates = await Future.wait(
      valid.map((entry) => _readPrivate(entry.$1)),
    );

    final pending = <AdminStation>[];
    final listed = <AdminStation>[];
    for (var index = 0; index < valid.length; index++) {
      final station = _mapStation(valid[index].$1, valid[index].$2, privates[index]);
      (station.status == StationApprovalStatus.pending ? pending : listed)
          .add(station);
    }

    int byCreatedAt(AdminStation a, AdminStation b) {
      final left = a.createdAt;
      final right = b.createdAt;
      if (left == null && right == null) return a.name.compareTo(b.name);
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    }

    // Pendente: mais antigo primeiro (quem esperou mais). Listado: mais
    // recente primeiro.
    pending.sort(byCreatedAt);
    listed.sort((a, b) => byCreatedAt(b, a));

    return AdminStationsState(
      pending: pending,
      listed: listed,
      invalidDocumentPaths: invalid,
    );
  }

  Future<Map<String, dynamic>?> _readPrivate(String uid) async {
    try {
      final document = await _firestore.collection('gas_stations').doc(uid).get();
      return document.data();
    } on FirebaseException catch (error, stack) {
      // Documento privado ausente ou sem permissão não derruba a fila: o
      // posto aparece marcado como "dados privados indisponíveis".
      developer.log(
        'gas_stations/$uid indisponível para o admin',
        name: 'admin',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  AdminStation _mapStation(
    String uid,
    Map<String, dynamic> public,
    Map<String, dynamic>? private,
  ) {
    String text(Object? value) => value is String ? value : '';
    DateTime? date(Object? value) =>
        value is Timestamp ? value.toDate() : null;

    return AdminStation(
      uid: uid,
      name: text(public['brandName']).isEmpty
          ? text(private?['brandName'])
          : text(public['brandName']),
      status: StationApprovalStatus.fromWire(public['status']),
      brand: StationBrand.fromWire(public['brand']),
      address: text(public['address']),
      neighborhood: text(public['neighborhood']),
      city: text(public['city']),
      state: text(public['state']),
      cep: text(public['cep']),
      cnpj: text(private?['cnpj']),
      email: text(private?['email']),
      phone: text(private?['phone']),
      createdAt: date(private?['createdAt']),
      privateDataMissing: private == null,
    );
  }

  Future<void> writeStationStatus(
    String uid,
    StationApprovalStatus status,
  ) => _firestore.collection('public_stations').doc(uid).update({
    'status': status.wireValue,
  });
}
