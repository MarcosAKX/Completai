// Coordena detalhe, reviews, favorito, rota e cacheia o resultado por posto.
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../domain/models/station_details.dart';
import '../../domain/models/station_details_state.dart';
import '../../domain/models/station_review_page.dart';
import '../../domain/repositories/station_details_repository.dart';
import '../services/station_details_service.dart';
import '../services/station_directions_service.dart';

class StationDetailsRepositoryImpl implements StationDetailsRepository {
  StationDetailsRepositoryImpl(
    this._service,
    this._directions, {
    required this.uidProvider,
  });

  final StationDetailsService _service;
  final StationDirectionsService _directions;
  final String? Function() uidProvider;
  final Map<String, StationDetailsState> _cache = {};

  @override
  Future<StationDetailsState> load(
    String stationUid, {
    bool forceRefresh = false,
  }) async {
    final cached = _cache[stationUid];
    if (!forceRefresh && cached != null) return cached;
    return guardInfra(() async {
      final details = await _service.readStation(stationUid);
      final reviews = await _service.readReviews(stationUid, limit: 3);
      final uid = uidProvider();
      final favorite = uid == null
          ? false
          : await _service.isFavorite(uid, stationUid);
      return _cache[stationUid] = StationDetailsState(
        details: details,
        reviews: reviews,
        isFavorite: favorite,
      );
    });
  }

  @override
  Future<void> setFavorite(String stationUid, {required bool favorite}) async {
    final uid = uidProvider();
    if (uid == null) throw const UnauthenticatedException();
    await guardInfra(
      () => _service.setFavorite(uid, stationUid, favorite: favorite),
    );
    final cached = _cache[stationUid];
    if (cached != null) {
      _cache[stationUid] = cached.copyWith(isFavorite: favorite);
    }
  }

  @override
  Future<void> submitReview(
    String stationUid, {
    required int rating,
    required String comment,
  }) async {
    final uid = uidProvider();
    if (uid == null) throw const UnauthenticatedException();
    await guardInfra(
      () => _service.writeReview(
        stationUid: stationUid,
        clientUid: uid,
        rating: rating,
        comment: comment,
      ),
    );
    _cache.remove(stationUid);
  }

  @override
  Future<StationReviewPage> loadReviewPage(
    String stationUid, {
    StationReviewCursor? after,
    int limit = 20,
  }) => guardInfra(
    () => _service.readReviewPage(stationUid, after: after, limit: limit),
  );

  @override
  Future<void> openDirections(StationDetails details) =>
      guardInfra(() => _directions.open(details.latitude, details.longitude));
}
