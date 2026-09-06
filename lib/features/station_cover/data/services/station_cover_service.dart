// Acesso a `station_covers/{uid}`: a foto do posto guardada como base64.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/jpeg_compressor.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../domain/models/station_cover.dart';

class StationCoverService {
  StationCoverService(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(FirestoreCollections.stationCovers).doc(uid);

  Future<StationCover?> read(String stationUid) async {
    final snapshot = await _doc(stationUid).get();
    final encoded = snapshot.data()?['image'];
    if (encoded is! String || encoded.isEmpty) return null;
    try {
      return StationCover(base64Decode(encoded));
    } on FormatException catch (error) {
      throw ValidationException('Foto do posto corrompida: ${error.message}');
    }
  }

  /// Comprime na hora de gravar (fora da thread da UI); o teto casa com o
  /// limite das rules.
  Future<void> write({
    required String stationUid,
    required Uint8List sourceBytes,
  }) async {
    final jpeg = await compressToJpegInBackground(sourceBytes);
    await _doc(stationUid).set({
      'uid': stationUid,
      'image': base64Encode(jpeg),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String stationUid) => _doc(stationUid).delete();
}
