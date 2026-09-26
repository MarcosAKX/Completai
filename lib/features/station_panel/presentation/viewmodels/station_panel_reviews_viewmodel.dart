// Paginação e denúncia das avaliações do próprio posto — Dart puro, sem
// import de Flutter, testável sem montar árvore de widget.
import 'package:riverpod/riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../station_details/domain/models/station_review.dart';
import '../../../station_details/domain/models/station_reviews_state.dart';
import '../../domain/repositories/station_panel_reviews_repository.dart';

class StationPanelReviewsViewModel
    extends FamilyAsyncNotifier<StationReviewsState, String> {
  StationPanelReviewsViewModel(this._repositoryProvider);

  final ProviderListenable<StationPanelReviewsRepository> _repositoryProvider;
  StationPanelReviewsRepository get _repository =>
      ref.read(_repositoryProvider);
  late String _stationUid;

  @override
  Future<StationReviewsState> build(String arg) async {
    _stationUid = arg;
    final page = await _repository.loadReviews(arg);
    return StationReviewsState(
      reviews: page.reviews,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  Future<bool> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return false;
    }
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    final result = await AsyncValue.guard(() async {
      final page = await _repository.loadReviews(
        _stationUid,
        after: current.nextCursor,
      );
      return StationReviewsState(
        reviews: [...current.reviews, ...page.reviews],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    });
    state = result;
    return !result.hasError;
  }

  /// Denuncia [review] para revisão do admin. Não altera a lista exibida —
  /// devolve a mensagem de erro (`null` em caso de sucesso) para a View
  /// mostrar sem derrubar o estado paginado.
  Future<String?> reportReview(StationReview review, String reason) async {
    try {
      await _repository.reportReview(
        stationUid: _stationUid,
        clientUid: review.clientUid,
        reason: reason,
      );
      return null;
    } on Failure catch (error) {
      return error.message;
    } on AppException catch (error) {
      // `_requireUid()` do Repository pode lançar antes de entrar no
      // guardInfra (mesmo padrão do StationPanelRepositoryImpl) — cobre
      // esse caso aqui para nunca deixar a denúncia quebrar sem mensagem.
      return error.message;
    }
  }
}
