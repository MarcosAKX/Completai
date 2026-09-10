// Contrato de leitura e edição dos dados privados do motorista.
import '../models/client_profile.dart';

abstract interface class ClientProfileRepository {
  Future<ClientProfile> load(String uid);
  Future<ClientProfile> save(
    String uid, {
    required String name,
    required String phone,
  });
}
