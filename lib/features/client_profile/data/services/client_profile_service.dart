// Acesso ao documento privado; atualiza somente nome e celular.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/client_profile.dart';

class ClientProfileService {
  ClientProfileService(this._firestore);
  final FirebaseFirestore _firestore;

  Future<ClientProfile> load(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null || data['type'] != 'client') {
      throw const InvalidProfileException();
    }
    return ClientProfile(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
    );
  }

  Future<void> save(
    String uid, {
    required String name,
    required String phone,
  }) => _firestore.collection('users').doc(uid).update({
    'name': name,
    'phone': phone,
  });
}
