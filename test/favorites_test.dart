// Lista privada: paginação, conta, remoção/desfazer e layout pequeno.
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:completai/core/errors/failures.dart';
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/presentation/providers/auth_providers.dart';
import 'package:completai/features/auth/presentation/viewmodels/session_viewmodel.dart';
import 'package:completai/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:completai/features/favorites/data/services/favorites_service.dart';
import 'package:completai/features/favorites/domain/models/favorites_page.dart';
import 'package:completai/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:completai/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:completai/features/favorites/presentation/views/favorites_page.dart';
import 'package:completai/features/station_details/data/services/station_details_service.dart';
import 'package:completai/features/station_details/domain/models/station_details.dart';
import 'package:completai/features/station_cover/domain/models/station_cover.dart';
import 'package:completai/features/station_cover/domain/repositories/station_cover_repository.dart';
import 'package:completai/features/station_cover/presentation/providers/station_cover_providers.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:completai/shared/models/station_fuel.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_viewmodel_test.dart' show TestAuthRepository;

const station = StationDetails(
  uid: 'a',
  name: 'Posto Avenida',
  brand: StationBrand.branca,
  address: 'Rua Um',
  neighborhood: 'Centro',
  city: 'Bebedouro',
  state: 'SP',
  latitude: 0,
  longitude: 0,
  prices: {StationFuel.gasolineRegular: 5.49},
  pricesUpdatedAt: null,
  openingHours: {},
  averageRating: 4,
  reviewCount: 2,
  services: [],
);

class FakeFavorites implements FavoritesRepository {
  List<StationDetails> items = [station];
  bool fail = false;
  @override
  Future<FavoritesPageData> load(
    String uid, {
    String? after,
    bool forceRefresh = false,
  }) async =>
      FavoritesPageData(stations: List.of(items), cursor: 'a', hasMore: false);
  @override
  Future<void> setFavorite(
    String uid,
    String id, {
    required bool favorite,
  }) async {
    if (fail) throw const NetworkFailure('Sem conexão');
    items = favorite ? [station] : [];
  }
}

class NoCovers implements StationCoverRepository {
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
  test(
    'pagina 20 referências sem duplicar e isola conta; posto excluído é omitido',
    () async {
      final db = FakeFirebaseFirestore();
      final service = FavoritesService(db, StationDetailsService(db));
      final repo = FavoritesRepositoryImpl(service);
      for (var i = 0; i < 22; i++) {
        final id = 's${i.toString().padLeft(2, '0')}';
        await db
            .collection('users')
            .doc('client')
            .collection('favorites')
            .doc(id)
            .set({'stationId': id, 'addedAt': Timestamp.now()});
        if (i != 0) {
          await db.collection('public_stations').doc(id).set({
            'brandName': id,
            'city': 'Bebedouro',
            'state': 'SP',
            'prices': <String, dynamic>{},
            'openingHours': <String, dynamic>{},
            'services': <String>[],
          });
        }
      }
      final first = await repo.load('client');
      expect(first.stations.length, 19);
      expect(first.hasMore, isTrue);
      final second = await repo.load('client', after: first.cursor);
      expect(second.stations.length, 2);
      expect(second.hasMore, isFalse);
      expect(
        {
          ...first.stations.map((s) => s.uid),
          ...second.stations.map((s) => s.uid),
        }.length,
        21,
      );
      expect((await repo.load('other')).stations, isEmpty);
      await repo.setFavorite('client', 's01', favorite: false);
      expect(
        (await repo.load('client')).stations.any((s) => s.uid == 's01'),
        isFalse,
      );
      await repo.setFavorite('client', 's01', favorite: true);
      expect(
        (await repo.load('client')).stations.any((s) => s.uid == 's01'),
        isTrue,
      );
    },
  );

  test('ViewModel busca, remove, desfaz e preserva dados em falha', () async {
    final repo = FakeFavorites();
    final container = ProviderContainer(
      overrides: [favoritesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final provider = favoritesViewModelProvider('client');
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final vm = container.read(provider.notifier);
    vm.search('centro');
    expect(container.read(provider).requireValue.visible.length, 1);
    repo.fail = true;
    expect(await vm.remove(station), isFalse);
    expect(container.read(provider).valueOrNull!.stations.length, 1);
    repo.fail = false;
    expect(await vm.remove(station), isTrue);
    expect(container.read(provider).requireValue.stations, isEmpty);
    expect(await vm.undo(station), isTrue);
    expect(container.read(provider).requireValue.search, 'centro');
    expect(container.read(provider).requireValue.stations.length, 1);
    vm.search('Inexistente');
    expect(container.read(provider).requireValue.visible, isEmpty);
  });

  testWidgets('favoritos cabem em 320x568; remoção pode ser desfeita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeFavorites();
    final auth = TestAuthRepository()
      ..session = const AuthSession(
        uid: 'client',
        email: 'a@b.com',
        role: AccountRole.client,
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesRepositoryProvider.overrideWithValue(repo),
          stationCoverRepositoryProvider.overrideWithValue(NoCovers()),
          authRepositoryProvider.overrideWithValue(auth),
          sessionViewModelProvider.overrideWith(
            () => SessionViewModel(authRepositoryProvider),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const FavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Posto Avenida'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byTooltip('Remover Posto Avenida dos favoritos'),
    );
    await tester.tap(find.byTooltip('Remover Posto Avenida dos favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Você ainda não salvou nenhum posto'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(find.text('Posto Avenida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
