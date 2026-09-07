// Navegação da home para o perfil público pelo uid do posto selecionado.
import 'dart:typed_data';

import 'package:completai/features/station_cover/domain/models/station_cover.dart';
import 'package:completai/features/station_cover/domain/repositories/station_cover_repository.dart';
import 'package:completai/features/station_cover/presentation/providers/station_cover_providers.dart';
import 'package:completai/features/station_details/domain/models/station_details.dart';
import 'package:completai/features/station_details/domain/models/station_details_state.dart';
import 'package:completai/features/station_details/domain/models/station_review_page.dart';
import 'package:completai/features/station_details/domain/repositories/station_details_repository.dart';
import 'package:completai/features/station_details/presentation/providers/station_details_providers.dart';
import 'package:completai/features/station_discovery/domain/models/station_discovery_result.dart';
import 'package:completai/features/station_discovery/domain/models/station_summary.dart';
import 'package:completai/features/station_discovery/domain/repositories/station_discovery_repository.dart';
import 'package:completai/features/station_discovery/presentation/providers/station_discovery_providers.dart';
import 'package:completai/features/station_discovery/presentation/views/station_discovery_page.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _summary = StationSummary(
  uid: 'station-1',
  name: 'Posto Avenida',
  brand: StationBrand.shell,
  neighborhood: 'Centro',
  city: 'Bebedouro',
  latitude: -20.94,
  longitude: -48.48,
  prices: {
    FuelType.gasoline: 5.79,
    FuelType.ethanol: 3.89,
    FuelType.diesel: 5.89,
  },
  averageRating: 4.8,
  reviewCount: 128,
  pricesUpdatedAt: null,
  todayHours: null,
  distanceKm: 1.2,
);

class _DiscoveryRepository implements StationDiscoveryRepository {
  @override
  Future<StationDiscoveryResult> loadCity(
    String city, {
    bool forceRefresh = false,
  }) async =>
      const StationDiscoveryResult(city: 'Bebedouro', stations: [_summary]);

  @override
  Future<StationDiscoveryResult> loadCurrentCity({bool forceRefresh = false}) =>
      loadCity('Bebedouro');
}

class _DetailsRepository implements StationDetailsRepository {
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
  }) async => const StationDetailsState(
    details: StationDetails(
      uid: 'station-1',
      name: 'Posto Avenida',
      brand: StationBrand.shell,
      address: 'Av. Brasil, 1000',
      neighborhood: 'Centro',
      city: 'Bebedouro',
      state: 'SP',
      latitude: -20.94,
      longitude: -48.48,
      prices: {},
      pricesUpdatedAt: null,
      openingHours: {},
      averageRating: 4.8,
      reviewCount: 128,
      services: [],
    ),
    reviews: [],
    isFavorite: false,
  );

  @override
  Future<void> openDirections(StationDetails details) async {}
  @override
  Future<void> setFavorite(String stationUid, {required bool favorite}) async {}
  @override
  Future<void> submitReview(
    String stationUid, {
    required int rating,
    required String comment,
  }) async {}
}

class _CoverRepository implements StationCoverRepository {
  @override
  Future<StationCover?> load(String stationUid) async => null;
  @override
  Future<void> remove(String stationUid) async {}
  @override
  Future<void> save({
    required String stationUid,
    required Uint8List sourceBytes,
  }) async {}
}

void main() {
  testWidgets('toque no card abre detalhes do posto', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDiscoveryRepositoryProvider.overrideWithValue(
            _DiscoveryRepository(),
          ),
          stationDetailsRepositoryProvider.overrideWithValue(
            _DetailsRepository(),
          ),
          stationCoverRepositoryProvider.overrideWithValue(_CoverRepository()),
        ],
        child: const MaterialApp(home: StationDiscoveryPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Posto Avenida'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Posto Avenida'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do posto'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Como chegar'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Como chegar'), findsOneWidget);
  });
}
