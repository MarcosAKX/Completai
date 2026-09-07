// Perfil público: conteúdo completo, ausência de telefone e responsividade.
import 'dart:typed_data';

import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/station_cover/domain/models/station_cover.dart';
import 'package:completai/features/station_cover/domain/repositories/station_cover_repository.dart';
import 'package:completai/features/station_cover/presentation/providers/station_cover_providers.dart';
import 'package:completai/features/station_details/domain/models/station_details.dart';
import 'package:completai/features/station_details/domain/models/station_details_state.dart';
import 'package:completai/features/station_details/domain/models/station_review.dart';
import 'package:completai/features/station_details/domain/models/station_review_page.dart';
import 'package:completai/features/station_details/domain/repositories/station_details_repository.dart';
import 'package:completai/features/station_details/presentation/providers/station_details_providers.dart';
import 'package:completai/features/station_details/presentation/views/station_details_page.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:completai/shared/models/station_fuel.dart';
import 'package:flutter/material.dart';
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
  openingHours: {'monday': StationOpeningPeriod(open: '06:00', close: '22:00')},
  averageRating: 4.8,
  reviewCount: 128,
  services: ['convenience', 'oil_change', 'tire_inflation'],
);

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
    details: _details,
    reviews: [
      StationReview(
        clientUid: 'client-1',
        clientName: 'Fernanda L.',
        rating: 5,
        comment: 'Posto muito bem organizado.',
        createdAt: null,
      ),
      StationReview(
        clientUid: 'client-2',
        clientName: 'Carlos M.',
        rating: 4,
        comment: 'Combustível de qualidade.',
        createdAt: null,
      ),
      StationReview(
        clientUid: 'client-3',
        clientName: 'Ana P.',
        rating: 5,
        comment: 'Atendimento rápido e organizado.',
        createdAt: null,
      ),
      StationReview(
        clientUid: 'client-4',
        clientName: 'João R.',
        rating: 3,
        comment: 'Comentário que pertence apenas à tela completa.',
        createdAt: null,
      ),
    ],
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
  testWidgets('perfil cabe em 320x568 e expõe todas as seções sem Ligar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailsRepositoryProvider.overrideWithValue(
            _DetailsRepository(),
          ),
          stationCoverRepositoryProvider.overrideWithValue(_CoverRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StationDetailsPage(
            stationUid: 'station-1',
            distanceKm: 1.2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do posto'), findsOneWidget);
    expect(find.text('Posto Avenida'), findsOneWidget);
    expect(find.text('Ligar'), findsNothing);
    expect(tester.takeException(), isNull, reason: 'conteúdo inicial');

    final scrollable = find.byType(Scrollable).first;
    for (final label in [
      'Como chegar',
      'Preços de combustível',
      'Serviços disponíveis',
      'Horário de funcionamento',
      'Avaliações',
      'Avaliar posto',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: scrollable,
      );
      expect(find.text(label), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'seção $label');
    }
    expect(find.text('Fernanda L.'), findsOneWidget);
    expect(find.text('Carlos M.'), findsOneWidget);
    expect(find.text('Ana P.'), findsOneWidget);
    expect(find.text('João R.'), findsNothing);
  });
}
