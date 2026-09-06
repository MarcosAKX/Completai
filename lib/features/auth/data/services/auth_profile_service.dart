// Lê e grava perfis. Cadastro sempre consulta o servidor para validar exclusividade.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/station_registration.dart';
import '../../../../shared/services/address_geocoding_service.dart';

class AuthProfileService {
  AuthProfileService(this._firestore, this._geocoding);
  final FirebaseFirestore _firestore;
  final AddressGeocodingService _geocoding;

  DocumentReference<Map<String, dynamic>> _client(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);
  DocumentReference<Map<String, dynamic>> _station(String uid) =>
      _firestore.collection(FirestoreCollections.gasStations).doc(uid);

  Future<AccountRole?> readRole(String uid) async {
    final documents = await Future.wait([
      _client(uid).get(const GetOptions(source: Source.server)),
      _station(uid).get(const GetOptions(source: Source.server)),
    ]);
    if (documents[0].exists && documents[1].exists) {
      throw const RoleConflictException();
    }
    for (var index = 0; index < documents.length; index++) {
      final data = documents[index].data();
      if (data == null) continue;
      final expected = index == 0 ? 'client' : 'gas_station';
      if (data['uid'] != uid || data['type'] != expected) {
        throw const InvalidProfileException();
      }
      return index == 0 ? AccountRole.client : AccountRole.gasStation;
    }
    return null;
  }

  Future<bool> _shouldCreateProfile(String uid, AccountRole requested) async {
    final existing = await readRole(uid);
    if (existing != null && existing != requested) {
      throw const RoleConflictException();
    }
    return existing == null;
  }

  Future<void> createClient({
    required String uid,
    required String email,
    required String name,
    required String phone,
  }) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      throw const ValidationException('Informe seu nome e celular.');
    }
    if (!await _shouldCreateProfile(uid, AccountRole.client)) return;
    await _client(uid).set({
      'uid': uid,
      'type': 'client',
      'name': name.trim(),
      'email': email,
      'phone': phone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createStation({
    required String uid,
    required String email,
    required StationRegistration registration,
  }) async {
    if (registration.cnpj.trim().isEmpty ||
        registration.brandName.trim().isEmpty ||
        registration.phone.trim().isEmpty ||
        registration.address.trim().isEmpty ||
        registration.neighborhood.trim().isEmpty ||
        registration.city.trim().isEmpty) {
      throw const ValidationException('Preencha todos os dados do posto.');
    }
    if (!await _shouldCreateProfile(uid, AccountRole.gasStation)) return;
    final coordinates = await _geocoding.resolve(
      '${registration.address.trim()}, ${registration.neighborhood.trim()}, '
      '${registration.city.trim()}, Brasil',
    );
    // Revalida após o trabalho externo de geocodificação; rules são a garantia real.
    if (!await _shouldCreateProfile(uid, AccountRole.gasStation)) return;
    final batch = _firestore.batch();
    batch.set(_station(uid), {
      'uid': uid,
      'type': 'gas_station',
      'cnpj': registration.cnpj.trim(),
      'email': email,
      'phone': registration.phone.trim(),
      'brandName': registration.brandName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore.collection(FirestoreCollections.publicStations).doc(uid),
      {
        'uid': uid,
        'brandName': registration.brandName.trim(),
        'address': registration.address.trim(),
        'neighborhood': registration.neighborhood.trim(),
        'city': coordinates.city,
        'citySearchKey': coordinates.citySearchKey,
        'state': coordinates.state,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'prices': {
          'gasolineRegular': null,
          'gasolineAdditive': null,
          'ethanol': null,
          'dieselS10': null,
          'dieselS500': null,
        },
        'pricesUpdatedAt': FieldValue.serverTimestamp(),
        'openingHours': {
          'monday': null,
          'tuesday': null,
          'wednesday': null,
          'thursday': null,
          'friday': null,
          'saturday': null,
          'sunday': null,
        },
        'averageRating': 0.0,
        'reviewCount': 0,
        'services': <String>[],
        'tags': <String>[],
      },
    );
    await batch.commit();
  }
}
