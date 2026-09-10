// Histórico: paginação, falhas preservando conteúdo e UI em tela pequena.
import 'package:completai/core/errors/failures.dart';
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/presentation/providers/auth_providers.dart';
import 'package:completai/features/auth/presentation/viewmodels/session_viewmodel.dart';
import 'package:completai/features/my_reviews/domain/models/my_review.dart';
import 'package:completai/features/my_reviews/domain/repositories/my_reviews_repository.dart';
import 'package:completai/features/my_reviews/presentation/providers/my_reviews_providers.dart';
import 'package:completai/features/my_reviews/presentation/views/my_reviews_page.dart';
import 'package:completai/features/station_cover/presentation/providers/station_cover_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_viewmodel_test.dart' show TestAuthRepository;
import 'favorites_test.dart' show station, NoCovers;

class HistoryRepository implements MyReviewsRepository {
  bool fail = false;
  final calls = <String>[];
  @override
  Future<MyReviewsPageData> load(
    String uid, {
    MyReviewsCursor? after,
    bool forceRefresh = false,
  }) async {
    calls.add(uid);
    if (fail) throw const NetworkFailure('Sem conexão');
    if (after != null) {
      return MyReviewsPageData(
        reviews: [
          MyReview(
            stationUid: 'removed',
            rating: 5,
            comment: '',
            createdAt: DateTime(2026, 9, 8),
          ),
        ],
      );
    }
    return MyReviewsPageData(
      reviews: [
        MyReview(
          stationUid: station.uid,
          station: station,
          rating: 3,
          comment: 'Bom atendimento. ' * 20,
          createdAt: DateTime(2026, 9, 9),
        ),
      ],
      cursor: const MyReviewsCursor(
        seconds: 1,
        nanoseconds: 1,
        path: 'public_stations/a/reviews/client',
      ),
      hasMore: true,
    );
  }
}

void main() {
  test(
    'ViewModel pagina, preserva busca/estado na falha e separa uid',
    () async {
      final repo = HistoryRepository();
      final container = ProviderContainer(
        overrides: [myReviewsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final provider = myReviewsViewModelProvider('client');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final vm = container.read(provider.notifier);
      vm.search('Centro');
      await vm.loadMore();
      expect(container.read(provider).requireValue.reviews.length, 2);
      expect(container.read(provider).requireValue.visible.length, 1);
      expect(container.read(provider).requireValue.hasMore, isFalse);
      repo.fail = true;
      await vm.refresh();
      expect(container.read(provider).hasError, isTrue);
      expect(container.read(provider).valueOrNull!.reviews.length, 2);
      repo.fail = false;
      final other = myReviewsViewModelProvider('other');
      container.listen(other, (_, _) {});
      await container.read(other.future);
      expect(repo.calls.last, 'other');
      expect(container.read(other).requireValue.search, '');
    },
  );

  testWidgets(
    'histórico mostra nota pessoal, comentário completo e posto indisponível em 320x568',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = TestAuthRepository()
        ..session = const AuthSession(
          uid: 'client',
          email: 'a@b.com',
          role: AccountRole.client,
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myReviewsRepositoryProvider.overrideWithValue(HistoryRepository()),
            stationCoverRepositoryProvider.overrideWithValue(NoCovers()),
            authRepositoryProvider.overrideWithValue(auth),
            sessionViewModelProvider.overrideWith(
              () => SessionViewModel(authRepositoryProvider),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MyReviewsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3,0'), findsOneWidget);
      expect(find.text('Bom atendimento. ' * 20), findsOneWidget);
      expect(tester.takeException(), isNull);
      final scrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Carregar mais'),
        200,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Posto indisponível'),
        150,
        scrollable: scrollable,
      );
      expect(find.text('Posto indisponível'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
