// Lista completa de avaliações: texto integral e paginação pelo ViewModel.
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/station_details/domain/models/station_details.dart';
import 'package:completai/features/station_details/domain/models/station_details_state.dart';
import 'package:completai/features/station_details/domain/models/station_review.dart';
import 'package:completai/features/station_details/domain/models/station_review_page.dart';
import 'package:completai/features/station_details/domain/repositories/station_details_repository.dart';
import 'package:completai/features/station_details/presentation/providers/station_details_providers.dart';
import 'package:completai/features/station_details/presentation/views/station_reviews_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements StationDetailsRepository {
  var page = 0;

  @override
  Future<StationReviewPage> loadReviewPage(
    String stationUid, {
    StationReviewCursor? after,
    int limit = 20,
  }) async {
    page++;
    return StationReviewPage(
      reviews: [
        StationReview(
          clientUid: 'client-$page',
          clientName: 'Cliente $page',
          rating: 5,
          comment: page == 1
              ? 'Comentário completo e detalhado que não deve ser cortado.'
              : 'Segunda página.',
          createdAt: DateTime(2026, 9, page),
        ),
      ],
      nextCursor: page == 1
          ? const StationReviewCursor(
              seconds: 1700000000,
              nanoseconds: 0,
              documentId: 'client-1',
            )
          : null,
      hasMore: page == 1,
    );
  }

  @override
  Future<StationDetailsState> load(
    String stationUid, {
    bool forceRefresh = false,
  }) => throw UnimplementedError();
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

void main() {
  testWidgets('mostra texto completo e carrega a próxima página', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StationReviewsPage(stationUid: 'station-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todas as avaliações'), findsOneWidget);
    expect(
      find.text('Comentário completo e detalhado que não deve ser cortado.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();
    expect(find.text('Segunda página.'), findsOneWidget);
  });
}
