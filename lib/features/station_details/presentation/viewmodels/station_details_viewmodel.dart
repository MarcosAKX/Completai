// Estado e ações do perfil público; não depende de widgets nem de Firebase.
import 'package:riverpod/riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/report_reason.dart';
import '../../domain/models/station_details_state.dart';
import '../../domain/models/station_review.dart';
import '../../domain/repositories/station_details_repository.dart';

class StationDetailsViewModel
    extends FamilyAsyncNotifier<StationDetailsState, String> {
  StationDetailsViewModel(this._repositoryProvider);

  final ProviderListenable<StationDetailsRepository> _repositoryProvider;

  StationDetailsRepository get _repository => ref.read(_repositoryProvider);
  late String _stationUid;

  @override
  Future<StationDetailsState> build(String arg) {
    _stationUid = arg;
    return _repository.load(arg);
  }

  Future<bool> refresh() => _run(
    () => _repository.load(_stationUid, forceRefresh: true),
    preservePrevious: true,
  );

  Future<bool> toggleFavorite() async {
    final current = state.valueOrNull;
    if (current == null || state.isLoading) return false;
    final target = !current.isFavorite;
    return _run(() async {
      await _repository.setFavorite(_stationUid, favorite: target);
      return current.copyWith(isFavorite: target);
    }, preservePrevious: true);
  }

  Future<bool> submitReview({required int rating, required String comment}) =>
      _run(() async {
        await _repository.submitReview(
          _stationUid,
          rating: rating,
          comment: comment,
        );
        return _repository.load(_stationUid, forceRefresh: true);
      }, preservePrevious: true);

  /// Denuncia a avaliação de outro cliente. Devolve `null` no sucesso, ou a
  /// mensagem de erro — a lista exibida NÃO muda: a avaliação continua no ar
  /// até o admin decidir, e esconder na hora daria a impressão errada de que
  /// a denúncia já valeu.
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
      // `uidProvider` e a checagem de autodenúncia lançam antes do
      // `guardInfra`, então não chegam como `Failure`.
      return error.message;
    }
  }

  Future<bool> openDirections() async {
    final current = state.valueOrNull;
    if (current == null || state.isLoading) return false;
    try {
      await _repository.openDirections(current.details);
      return true;
    } catch (error, stack) {
      state = AsyncValue<StationDetailsState>.error(
        error,
        stack,
      ).copyWithPrevious(state);
      return false;
    }
  }

  Future<bool> _run(
    Future<StationDetailsState> Function() action, {
    bool preservePrevious = false,
  }) async {
    if (state.isLoading) return false;
    state = preservePrevious
        ? const AsyncValue<StationDetailsState>.loading().copyWithPrevious(
            state,
          )
        : const AsyncValue<StationDetailsState>.loading();
    final result = await AsyncValue.guard(action);
    state = result;
    return !result.hasError;
  }
}
