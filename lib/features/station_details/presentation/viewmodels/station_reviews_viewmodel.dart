// Paginação das avaliações públicas sem dependência de widgets ou Firebase.
import 'package:riverpod/riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/report_reason.dart';
import '../../domain/models/station_review.dart';
import '../../domain/models/station_reviews_state.dart';
import '../../domain/repositories/station_details_repository.dart';

class StationReviewsViewModel
    extends FamilyAsyncNotifier<StationReviewsState, String> {
  StationReviewsViewModel(this._repositoryProvider);

  final ProviderListenable<StationDetailsRepository> _repositoryProvider;
  StationDetailsRepository get _repository => ref.read(_repositoryProvider);
  late String _stationUid;

  @override
  Future<StationReviewsState> build(String arg) async {
    _stationUid = arg;
    final page = await _repository.loadReviewPage(arg);
    return StationReviewsState(
      reviews: page.reviews,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  /// Mesma denúncia da prévia, para a lista completa. Devolve `null` no
  /// sucesso ou a mensagem de erro; a lista não muda, porque a avaliação
  /// continua no ar até o admin decidir.
  Future<String?> reportReview(
    StationReview review,
    ReportReason reason,
  ) async {
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
      return error.message;
    }
  }

  Future<bool> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return false;
    }
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    final result = await AsyncValue.guard(() async {
      final page = await _repository.loadReviewPage(
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
}
