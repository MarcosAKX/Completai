// Implementação da foto do posto: compressão + Firestore, com cache em
// memória por uid para não rebaixar a mesma imagem a cada card visível.
import 'dart:typed_data';

import '../../../../core/errors/failure_mapper.dart';
import '../../domain/models/station_cover.dart';
import '../../domain/repositories/station_cover_repository.dart';
import '../services/station_cover_service.dart';

class StationCoverRepositoryImpl implements StationCoverRepository {
  StationCoverRepositoryImpl(this._service);
  final StationCoverService _service;

  // uid -> foto (ou null quando o posto não tem foto). Presença da chave
  // indica que já consultamos.
  final Map<String, StationCover?> _cache = {};

  @override
  Future<StationCover?> load(String stationUid) async {
    if (_cache.containsKey(stationUid)) return _cache[stationUid];
    final cover = await guardInfra(() => _service.read(stationUid));
    return _cache[stationUid] = cover;
  }

  @override
  Future<void> save({
    required String stationUid,
    required Uint8List sourceBytes,
  }) async {
    await guardInfra(
      () => _service.write(stationUid: stationUid, sourceBytes: sourceBytes),
    );
    _cache.remove(stationUid);
  }

  @override
  Future<void> remove(String stationUid) async {
    await guardInfra(() => _service.delete(stationUid));
    _cache[stationUid] = null;
  }
}
