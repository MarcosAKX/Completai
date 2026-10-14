// Fila de aprovação: carrega, aprova e recusa. Sem dependência de widget.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/models/admin_stations_state.dart';
import '../../../../shared/models/station_approval_status.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminStationsViewModel extends AsyncNotifier<AdminStationsState> {
  AdminStationsViewModel(this._repositoryProvider);

  final ProviderListenable<AdminRepository> _repositoryProvider;

  AdminRepository get _repository => ref.read(_repositoryProvider);

  @override
  Future<AdminStationsState> build() => _repository.loadStations();

  Future<void> refresh() async {
    state = const AsyncLoading<AdminStationsState>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => _repository.loadStations(forceRefresh: true),
    );
  }

  Future<String?> approve(String uid) =>
      _setStatus(uid, StationApprovalStatus.approved);

  Future<String?> reject(String uid) =>
      _setStatus(uid, StationApprovalStatus.rejected);

  /// Retorna `null` em caso de sucesso, ou a mensagem de erro.
  ///
  /// A lista só muda depois que a escrita confirma: aprovar e ver o posto
  /// pular de aba sem o Firestore ter aceitado seria mentira na tela.
  Future<String?> _setStatus(String uid, StationApprovalStatus status) async {
    final previous = state;
    state = const AsyncLoading<AdminStationsState>().copyWithPrevious(state);
    try {
      await _repository.setStationStatus(uid, status);
      state = await AsyncValue.guard(
        () => _repository.loadStations(forceRefresh: true),
      );
      return null;
    } on Failure catch (error) {
      state = previous;
      return error.message;
    } on AppException catch (error) {
      state = previous;
      return error.message;
    }
  }
}
