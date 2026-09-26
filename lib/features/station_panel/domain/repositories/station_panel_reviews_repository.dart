// Contrato de leitura/denúncia das avaliações do próprio posto. Reaproveita
// os modelos e o serviço de dados já usados pelo perfil público do posto
// (mesma coleção `public_stations/{uid}/reviews`), sem duplicar paginação.
import '../../../station_details/domain/models/station_review_page.dart';

abstract interface class StationPanelReviewsRepository {
  /// Página de avaliações do posto do dono logado.
  Future<StationReviewPage> loadReviews(
    String stationUid, {
    StationReviewCursor? after,
    int limit = 20,
  });

  /// Denuncia a avaliação de [clientUid] para revisão do admin.
  /// O uid de quem denuncia é resolvido internamente (dono logado).
  Future<void> reportReview({
    required String stationUid,
    required String clientUid,
    required String reason,
  });
}
