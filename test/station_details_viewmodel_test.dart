// ViewModel do detalhe: carga, refresh, favorito e avaliação.
import 'package:completai/features/station_details/domain/models/station_details.dart';
import 'package:completai/features/station_details/domain/models/station_details_state.dart';
import 'package:completai/features/station_details/domain/models/station_review.dart';
import 'package:completai/features/station_details/domain/models/station_review_page.dart';
import 'package:completai/features/station_details/domain/repositories/station_details_repository.dart';
import 'package:completai/features/station_details/presentation/providers/station_details_providers.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:completai/shared/models/station_fuel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _details = StationDetails(
  uid: 'station-1',
  name: 'Posto Avenida',
  brand: StationBrand.shell,
  address: 'Av. Brasil, 1000',
  neighborhood: 'Centro',
  city: 'Bebedouro',
  state: 'SP',
  latitude: -20.94,
  longitude: -48.48,
  prices: {
    StationFuel.gasolineRegular: 5.79,
    StationFuel.gasolineAdditive: 5.99,
    StationFuel.ethanol: 3.89,
    StationFuel.dieselS10: 5.89,
    StationFuel.dieselS500: 5.69,
  },
  pricesUpdatedAt: null,
  openingHours: {},
  averageRating: 4.8,
  reviewCount: 128,
  services: [],
);

class _FakeRepository implements StationDetailsRepository {
  bool favorite = false;
  int loads = 0;
  int reviewsWritten = 0;
  bool directionsOpened = false;

  @override
  Future<StationReviewPage> loadReviewPage(
    String stationUid, {
    StationReviewCursor? after,
    int limit = 20,
  }) async =>
      const StationReviewPage(reviews: [], nextCursor: null, hasMore: false);

  @override
  Future<StationDetailsState> load(
    String stationUid, {
    bool forceRefresh = false,
  }) async {
    loads++;
    return StationDetailsState(
      details: _details,
      reviews: const <StationReview>[],
      isFavorite: favorite,
    );
  }

  @override
  Future<void> setFavorite(String stationUid, {required bool favorite}) async {
    this.favorite = favorite;
  }

  @override
  Future<void> submitReview(
    String stationUid, {
    required int rating,
    required String comment,
  }) async {
    reviewsWritten++;
  }

  @override
  Future<void> openDirections(StationDetails details) async {
    directionsOpened = true;
  }
}

void main() {
  test('carrega detalhe e atualiza favorito', () async {
    final repository = _FakeRepository();
    final container = ProviderContainer(
      overrides: [
        stationDetailsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(
      stationDetailsViewModelProvider('station-1').future,
    );
    expect(initial.details.name, 'Posto Avenida');
    expect(initial.isFavorite, isFalse);

    final ok = await container
        .read(stationDetailsViewModelProvider('station-1').notifier)
        .toggleFavorite();

    expect(ok, isTrue);
    expect(repository.favorite, isTrue);
    expect(
      container
          .read(stationDetailsViewModelProvider('station-1'))
          .requireValue
          .isFavorite,
      isTrue,
    );
  });

  test('avalia e recarrega o detalhe', () async {
    final repository = _FakeRepository();
    final container = ProviderContainer(
      overrides: [
        stationDetailsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(stationDetailsViewModelProvider('station-1').future);

    final ok = await container
        .read(stationDetailsViewModelProvider('station-1').notifier)
        .submitReview(rating: 5, comment: 'Excelente.');

    expect(ok, isTrue);
    expect(repository.reviewsWritten, 1);
    expect(repository.loads, 2);
  });
}
