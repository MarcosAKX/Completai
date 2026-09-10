// Coordena estado e paginação do histórico sem dependência de widgets.
import 'package:riverpod/riverpod.dart';
import '../../domain/models/my_reviews_state.dart';
import '../../domain/repositories/my_reviews_repository.dart';

class MyReviewsViewModel
    extends AutoDisposeFamilyAsyncNotifier<MyReviewsState, String> {
  MyReviewsViewModel(this.repositoryProvider);
  final ProviderListenable<MyReviewsRepository> repositoryProvider;
  late MyReviewsRepository _repository;
  late String _uid;
  bool _disposed = false;
  @override
  Future<MyReviewsState> build(String arg) async {
    _uid = arg;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _repository = ref.watch(repositoryProvider);
    final page = await _repository.load(arg, forceRefresh: true);
    return MyReviewsState(
      reviews: page.reviews,
      cursor: page.cursor,
      hasMore: page.hasMore,
    );
  }

  void search(String value) {
    if (state.isLoading || !state.hasValue) return;
    state = AsyncData(state.requireValue.withSearch(value));
  }

  Future<void> refresh() => _load(false);
  Future<void> loadMore() => _load(true);
  Future<void> _load(bool more) async {
    if (state.isLoading || !state.hasValue) return;
    final previous = state;
    final current = previous.requireValue;
    if (more && (!current.hasMore || current.cursor == null)) return;
    state = const AsyncValue<MyReviewsState>.loading().copyWithPrevious(
      previous,
    );
    final result = await AsyncValue.guard(() async {
      final page = await _repository.load(
        _uid,
        after: more ? current.cursor : null,
        forceRefresh: !more,
      );
      final entries = {
        if (more)
          for (final review in current.reviews) review.stationUid: review,
        for (final review in page.reviews) review.stationUid: review,
      };
      return MyReviewsState(
        reviews: entries.values.toList(),
        cursor: page.cursor,
        hasMore: page.hasMore,
        search: current.search,
      );
    });
    if (!_disposed) {
      state = result.hasError ? result.copyWithPrevious(previous) : result;
    }
  }
}
