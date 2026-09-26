// A cidade é fixa no MVP: cadastro e perfil do posto não deixam editá-la e
// sempre gravam `ServiceArea.primaryCity`, mesmo se o documento tiver outra.
import 'dart:typed_data';

import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/domain/models/station_registration.dart';
import 'package:completai/features/auth/domain/repositories/auth_repository.dart';
import 'package:completai/features/auth/presentation/providers/auth_providers.dart';
import 'package:completai/features/auth/presentation/views/station_registration_step2_page.dart';
import 'package:completai/features/station_cover/domain/models/station_cover.dart';
import 'package:completai/features/station_cover/domain/repositories/station_cover_repository.dart';
import 'package:completai/features/station_cover/presentation/providers/station_cover_providers.dart';
import 'package:completai/features/station_panel/domain/models/opening_hours.dart';
import 'package:completai/features/station_panel/domain/models/station_fuel.dart';
import 'package:completai/features/station_panel/domain/models/station_profile.dart';
import 'package:completai/features/station_panel/domain/repositories/station_panel_repository.dart';
import 'package:completai/features/station_panel/presentation/providers/station_panel_providers.dart';
import 'package:completai/features/station_panel/presentation/views/station_profile_page.dart';
import 'package:completai/shared/models/service_area.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingAuthRepository implements AuthRepository {
  StationRegistration? captured;

  @override
  Future<AuthSession> createAccount({
    required String email,
    required String password,
  }) async => AuthSession(uid: 'u1', email: email);

  @override
  Future<AuthSession> completeStationRegistration(
    StationRegistration registration,
  ) async {
    captured = registration;
    return const AuthSession(uid: 'u1', email: 'posto@example.com');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthSession?> restoreSession({bool forceRefresh = false}) async =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Posto gravado fora da área atendida — prova que a tela não propaga a
/// cidade antiga do documento.
class _CapturingPanelRepository implements StationPanelRepository {
  String? savedCity;

  StationProfile get _profile => StationProfile(
    uid: 'station-1',
    name: 'Posto Teste',
    cnpj: '12345678000190',
    phone: '(17) 3333-4444',
    email: 'p@e.test',
    brand: StationBrand.branca,
    address: 'Rua 1, 10',
    street: 'Rua 1',
    number: '10',
    neighborhood: 'Centro',
    city: 'Campinas',
    state: 'SP',
    prices: {for (final fuel in StationFuel.values) fuel: null},
    services: const [],
    tags: const [],
    openingHours: const WeeklyHours.empty(),
  );

  @override
  Future<StationProfile> saveAddress({
    required String street,
    required String number,
    required String neighborhood,
    required String city,
    required String cep,
  }) async {
    savedCity = city;
    return _profile;
  }

  @override
  Future<StationProfile> loadProfile({bool forceRefresh = false}) async =>
      _profile;

  @override
  Future<StationProfile> savePrices(Map<StationFuel, double?> prices) async =>
      _profile;

  @override
  Future<StationProfile> saveIdentity({
    required String name,
    required String phone,
  }) async => _profile;

  @override
  Future<StationProfile> saveBrand(StationBrand brand) async => _profile;

  @override
  Future<StationProfile> saveInfo({
    required List<String> services,
    required List<String> tags,
  }) async => _profile;

  @override
  Future<StationProfile> saveOpeningHours(WeeklyHours hours) async => _profile;
}

class _NoCoverRepository implements StationCoverRepository {
  @override
  Future<StationCover?> load(String stationUid) async => null;
  @override
  Future<void> save({
    required String stationUid,
    required Uint8List sourceBytes,
  }) async {}
  @override
  Future<void> remove(String stationUid) async {}
}

const _draft = StationRegistrationDraft(
  brandName: 'Posto Teste',
  cnpj: '12.345.678/0001-90',
  phone: '(17) 3333-4444',
  email: 'posto@example.com',
  password: 'senha123',
);

void main() {
  testWidgets('cadastro do posto trava a cidade e grava a do MVP', (
    tester,
  ) async {
    final auth = _CapturingAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StationRegistrationStep2Page(draft: _draft),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ServiceArea.primaryCity), findsOneWidget);
    // Rua, número, CEP e bairro seguem editáveis; a cidade não é mais campo.
    expect(find.byType(TextFormField), findsNWidgets(4));

    await tester.enterText(find.byType(TextFormField).at(0), 'Rua Sete');
    await tester.enterText(find.byType(TextFormField).at(1), '100');
    await tester.enterText(find.byType(TextFormField).at(2), '14700000');
    await tester.enterText(find.byType(TextFormField).at(3), 'Centro');
    await tester.tap(find.text('Finalizar Cadastro'));
    await tester.pumpAndSettle();

    expect(auth.captured?.city, ServiceArea.primaryCity);
    expect(auth.captured?.street, 'Rua Sete');
    expect(auth.captured?.number, '100');
    expect(auth.captured?.cep, '14700-000');
  });

  testWidgets('perfil do posto trava a cidade mesmo com outra no documento', (
    tester,
  ) async {
    final panel = _CapturingPanelRepository();
    final container = ProviderContainer(
      overrides: [
        stationPanelRepositoryProvider.overrideWithValue(panel),
        stationCoverRepositoryProvider.overrideWithValue(_NoCoverRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(stationPanelViewModelProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const StationProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ServiceArea.primaryCity), findsOneWidget);
    expect(find.text('Campinas'), findsNothing);

    // nome(0), celular(1), rua(2), número(3), CEP(4), bairro(5)
    await tester.enterText(find.byType(TextFormField).at(2), 'Rua Nova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(panel.savedCity, ServiceArea.primaryCity);
  });
}
