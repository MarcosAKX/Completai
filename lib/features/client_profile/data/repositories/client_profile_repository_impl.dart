// Valida e traduz falhas de infraestrutura antes de expor os dados ao ViewModel.
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../domain/models/client_profile.dart';
import '../../domain/repositories/client_profile_repository.dart';
import '../services/client_profile_service.dart';

class ClientProfileRepositoryImpl implements ClientProfileRepository {
  ClientProfileRepositoryImpl(this._service);
  final ClientProfileService _service;

  @override
  Future<ClientProfile> load(String uid) =>
      guardInfra(() => _service.load(uid));

  @override
  Future<ClientProfile> save(
    String uid, {
    required String name,
    required String phone,
  }) => guardInfra(() async {
    final normalizedName = name.trim();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (normalizedName.isEmpty || normalizedName.length > 100) {
      throw const ValidationException(
        'Informe um nome com até 100 caracteres.',
      );
    }
    if (digits.length < 10 || digits.length > 11) {
      throw const ValidationException('Informe um celular com DDD.');
    }
    final previous = await _service.load(uid);
    await _service.save(uid, name: normalizedName, phone: digits);
    return ClientProfile(
      uid: uid,
      name: normalizedName,
      email: previous.email,
      phone: digits,
    );
  });
}
