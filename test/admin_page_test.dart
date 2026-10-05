// Tela de admin: as três abas, os dados de conferência e as ações.
import 'package:completai/core/theme/app_theme.dart';
import 'package:completai/features/admin/domain/models/admin_station.dart';
import 'package:completai/features/admin/domain/models/admin_stations_state.dart';
import 'package:completai/features/admin/domain/models/report_status.dart';
import 'package:completai/features/admin/domain/models/review_report.dart';
import 'package:completai/features/admin/domain/repositories/admin_repository.dart';
import 'package:completai/features/admin/presentation/providers/admin_providers.dart';
import 'package:completai/features/admin/presentation/views/admin_page.dart';
import 'package:completai/features/auth/domain/models/auth_session.dart';
import 'package:completai/features/auth/domain/repositories/auth_repository.dart';
import 'package:completai/features/auth/presentation/providers/auth_providers.dart';
import 'package:completai/features/station_details/domain/models/station_review.dart';
import 'package:completai/shared/models/report_reason.dart';
import 'package:completai/shared/models/station_approval_status.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession({bool forceRefresh = false}) async =>
      const AuthSession(uid: 'admin', email: 'admin@example.test', isAdmin: true);
  @override
  Future<void> signOut() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAdminRepository implements AdminRepository {
  _StubAdminRepository({required this.stations, required this.reports});

  AdminStationsState stations;
  List<ReviewReport> reports;
  (String, StationApprovalStatus)? lastWrite;

  @override
  Future<AdminStationsState> loadStations({bool forceRefresh = false}) async =>
      stations;

  @override
  Future<void> setStationStatus(
    String uid,
    StationApprovalStatus status,
  ) async {
    lastWrite = (uid, status);
    stations = AdminStationsState(
      pending: stations.pending.where((s) => s.uid != uid).toList(),
      listed: stations.listed,
    );
  }

  @override
  Future<ReviewReportPage> loadReports({
    ReviewReportCursor? after,
    int limit = 20,
  }) async =>
      ReviewReportPage(reports: reports, nextCursor: null, hasMore: false);

  @override
  Future<void> dismissReport(ReviewReport report) async {}

  @override
  Future<void> removeReportedReview(ReviewReport report) async {}
}

AdminStation _station(String uid, StationApprovalStatus status) => AdminStation(
  uid: uid,
  name: 'Posto $uid',
  status: status,
  brand: StationBrand.branca,
  address: 'Rua Um, 100',
  neighborhood: 'Centro',
  city: 'Bebedouro',
  state: 'SP',
  cep: '14700000',
  cnpj: '12345678000190',
  email: 'posto@example.test',
  phone: '(17) 3333-4444',
);

Future<_StubAdminRepository> _pump(
  WidgetTester tester, {
  AdminStationsState? stations,
  List<ReviewReport>? reports,
}) async {
  final repository = _StubAdminRepository(
    stations:
        stations ??
        AdminStationsState(
          pending: [_station('p1', StationApprovalStatus.pending)],
          listed: [_station('p2', StationApprovalStatus.approved)],
        ),
    reports: reports ?? const [],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(_StubAuthRepository()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const AdminPage()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('abre em Pendentes e mostra os dados de conferência', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Posto p1'), findsOneWidget);
    // O que o admin precisa para decidir, com máscara aplicada.
    expect(find.text('12.345.678/0001-90'), findsOneWidget);
    expect(find.text('14700-000'), findsOneWidget);
    expect(find.text('posto@example.test'), findsOneWidget);
    expect(find.text('Aprovar'), findsOneWidget);
    expect(find.text('Recusar'), findsOneWidget);
  });

  testWidgets('aprovar escreve o status approved', (tester) async {
    final repository = await _pump(tester);

    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();

    expect(repository.lastWrite, ('p1', StationApprovalStatus.approved));
  });

  testWidgets('recusar pede confirmação antes de escrever', (tester) async {
    final repository = await _pump(tester);

    await tester.tap(find.text('Recusar'));
    await tester.pumpAndSettle();
    expect(find.text('Recusar este posto?'), findsOneWidget);
    expect(repository.lastWrite, isNull);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.lastWrite, isNull);
  });

  testWidgets('fila vazia explica o que vai aparecer ali', (tester) async {
    await _pump(
      tester,
      stations: const AdminStationsState(pending: [], listed: []),
    );

    expect(find.text('Nenhum posto esperando'), findsOneWidget);
  });

  testWidgets('aba Postos listados mostra os já revisados', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Postos listados'));
    await tester.pumpAndSettle();

    expect(find.text('Posto p2'), findsOneWidget);
    expect(find.text('1 posto revisado'), findsOneWidget);
    // Posto aprovado só oferece a ação contrária.
    expect(find.text('Recusar'), findsOneWidget);
    expect(find.text('Aprovar'), findsNothing);
  });

  testWidgets('aba Denúncias mostra o texto denunciado e as ações', (
    tester,
  ) async {
    await _pump(
      tester,
      reports: [
        ReviewReport(
          stationUid: 'p1',
          clientUid: 'bob',
          reporterUid: 'p1',
          reason: ReportReason.offensive,
          status: ReportStatus.pending,
          createdAt: DateTime(2026, 9, 1),
          stationName: 'Posto Um',
          review: const StationReview(
            clientUid: 'bob',
            clientName: 'Bob',
            rating: 2,
            comment: 'Texto que o posto denunciou',
            createdAt: null,
          ),
        ),
      ],
    );

    await tester.tap(find.text('Denúncias'));
    await tester.pumpAndSettle();

    expect(find.text('Linguagem ofensiva'), findsOneWidget);
    expect(find.text('Denunciado por Posto Um'), findsOneWidget);
    // O admin decide lendo o conteúdo, não só o motivo.
    expect(find.text('Texto que o posto denunciou'), findsOneWidget);
    expect(find.text('Manter'), findsOneWidget);
    expect(find.text('Remover'), findsOneWidget);
  });

  testWidgets('denúncia sem avaliação não oferece remover', (tester) async {
    await _pump(
      tester,
      reports: [
        ReviewReport(
          stationUid: 'p1',
          clientUid: 'bob',
          reporterUid: 'p1',
          reason: ReportReason.spam,
          status: ReportStatus.pending,
          createdAt: DateTime(2026, 9, 1),
          stationName: 'Posto Um',
          reviewMissing: true,
        ),
      ],
    );

    await tester.tap(find.text('Denúncias'));
    await tester.pumpAndSettle();

    expect(find.text('A avaliação já não existe mais.'), findsOneWidget);
    expect(find.text('Manter'), findsOneWidget);
    expect(find.text('Remover'), findsNothing);
  });
}
