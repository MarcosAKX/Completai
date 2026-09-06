// Contrato da foto do posto. Documento separado de `public_stations` para
// não pesar na query da listagem — ver ARCHITECTURE.md seção 6.
import 'dart:typed_data';

import '../models/station_cover.dart';

abstract interface class StationCoverRepository {
  /// Foto do posto [stationUid], ou `null` se ele não tem foto.
  /// Carregada sob demanda (detalhe / card visível), nunca em massa.
  Future<StationCover?> load(String stationUid);

  /// Comprime [sourceBytes] para JPEG dentro do teto e grava em
  /// `station_covers/{stationUid}`. Só o próprio dono passa nas rules.
  Future<void> save({
    required String stationUid,
    required Uint8List sourceBytes,
  });

  /// Remove a foto do posto.
  Future<void> remove(String stationUid);
}
