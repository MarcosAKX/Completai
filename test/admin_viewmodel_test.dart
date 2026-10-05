// ViewModels de admin testadas sem montar árvore de widget, com um
// repository falso que implementa a interface de domínio.
import 'package:completai/core/errors/failures.dart';
import 'package:completai/features/admin/domain/models/admin_station.dart';
import 'package:completai/features/admin/domain/models/admin_stations_state.dart';
import 'package:completai/features/admin/domain/models/report_status.dart';
import 'package:completai/features/admin/domain/models/review_report.dart';
import 'package:completai/features/admin/domain/repositories/admin_repository.dart';
import 'package:completai/features/admin/presentation/providers/admin_providers.dart';
import 'package:completai/features/station_details/domain/models/station_review.dart';
import 'package:completai/shared/models/report_reason.dart';
import 'package:completai/shared/models/station_approval_status.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AdminStation _station(String uid, StationApprovalStatus status) => AdminStation(
  uid: uid,
  name: 'Posto $uid',
  status: status,
  brand: StationBrand.branca,
  address: 'Rua Um, 100',
  neighborhood: 'Centro',
  city: 'Bebedouro',
  state: 'SP',
);

ReviewReport _report({
  ReportStatus status = ReportStatus.pending,
  bool withReview = true,
}) => ReviewReport(
  stationUid: 'p1',
  clientUid: 'bob',
  reporterUid: 'p1',
  reason: ReportReason.offensive,
  status: status,
  createdAt: DateTime(2026, 9, 1),
  stationName: 'Posto Um',
  review: withReview
      ? const StationReview(
          clientUid: 'bob',
          clientName: 'Bob',
          rating: 3,
          comment: 'Comentario',
          createdAt: null,
        )
      : null,
  reviewMissing: !withReview,
);

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({this.failWith});

  Failure? failWith;

  var stations = AdminStationsState(
    pending: [_station('p1', StationApprovalStatus.pending)],
    listed: [_station('p2', StationApprovalStatus.approved)],
  );

  List<ReviewReport> reports = [_report()];

  int loadCount = 0;
  int dismissCount = 0;
  int removeCount = 0;
  (String, StationApprovalStatus)? lastStatusWrite;
  ReviewReportCursor? lastCursor;

  @override
  Future<AdminStationsState> loadStations({bool forceRefresh = false}) async {
    loadCount++;
    return stations;
  }

  @override
  Future<void> setStationStatus(
    String uid,
    StationApprovalStatus status,
  ) async {
    if (failWith != null) throw failWith!;
    lastStatusWrite = (uid, status);
    // Espelha o efeito real: o posto sai da fila e vai para os listados.
    stations = AdminStationsState(
      pending: stations.pending.where((s) => s.uid != uid).toList(),
      listed: [...stations.listed, _station(uid, status)],
    );
  }

  @override
  Future<ReviewReportPage> loadReports({
    ReviewReportCursor? after,
    int limit = 20,
  }) async {
    lastCursor = after;
    return ReviewReportPage(
      reports: reports,
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> dismissReport(ReviewReport report) async {
    if (failWith != null) throw failWith!;
    dismissCount++;
  }

  @override
  Future<void> removeReportedReview(ReviewReport report) async {
    if (failWith != null) throw failWith!;
    removeCount++;
  }
}

ProviderContainer _container(FakeAdminRepository repository) {
  final container = ProviderContainer(
    overrides: [adminRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AdminStationsViewModel', () {
    test('carrega fila e listados', () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);

      final state = await container.read(adminStationsViewModelProvider.future);

      expect(state.pendingCount, 1);
      expect(state.listed, hasLength(1));
    });

    test('aprovar escreve e recarrega a fila', () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);
      await container.read(adminStationsViewModelProvider.future);
      final loadsBefore = repository.loadCount;

      final error = await container
          .read(adminStationsViewModelProvider.notifier)
          .approve('p1');

      expect(error, isNull);
      expect(repository.lastStatusWrite, ('p1', StationApprovalStatus.approved));
      // Recarregou em vez de remendar a lista na mão.
      expect(repository.loadCount, greaterThan(loadsBefore));
      expect(
        container.read(adminStationsViewModelProvider).requireValue.pending,
        isEmpty,
      );
    });

    test('recusar usa o status rejected', () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);
      await container.read(adminStationsViewModelProvider.future);

      await container
          .read(adminStationsViewModelProvider.notifier)
          .reject('p1');

      expect(repository.lastStatusWrite, ('p1', StationApprovalStatus.rejected));
    });

    test('falha devolve a mensagem e preserva o estado anterior', () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);
      await container.read(adminStationsViewModelProvider.future);
      repository.failWith = const PermissionFailure('Sem permissão.');

      final error = await container
          .read(adminStationsViewModelProvider.notifier)
          .approve('p1');

      expect(error, 'Sem permissão.');
      // A fila não muda só porque a tela tentou: o posto continua pendente.
      final state = container.read(adminStationsViewModelProvider);
      expect(state.requireValue.pendingCount, 1);
    });
  });

  group('AdminReportsViewModel', () {
    test('carrega a primeira página e conta as pendentes', () async {
      final container = _container(FakeAdminRepository());

      final state = await container.read(adminReportsViewModelProvider.future);

      expect(state.reports, hasLength(1));
      expect(state.pendingCount, 1);
      expect(state.hasMore, isFalse);
    });

    test('descartar marca dismissed sem recarregar a lista', () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);
      final state = await container.read(adminReportsViewModelProvider.future);

      final error = await container
          .read(adminReportsViewModelProvider.notifier)
          .dismiss(state.reports.single);

      expect(error, isNull);
      expect(repository.dismissCount, 1);
      final updated = container.read(adminReportsViewModelProvider).requireValue;
      expect(updated.reports.single.status, ReportStatus.dismissed);
      // A avaliação continua anexada: descartar não a remove.
      expect(updated.reports.single.review, isNotNull);
      expect(updated.pendingCount, 0);
    });

    test('remover marca resolved e solta a avaliação do item', () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);
      final state = await container.read(adminReportsViewModelProvider.future);

      final error = await container
          .read(adminReportsViewModelProvider.notifier)
          .removeReview(state.reports.single);

      expect(error, isNull);
      expect(repository.removeCount, 1);
      final updated = container.read(adminReportsViewModelProvider).requireValue;
      expect(updated.reports.single.status, ReportStatus.resolved);
      expect(updated.reports.single.review, isNull);
      expect(updated.reports.single.reviewMissing, isTrue);
      expect(updated.reports.single.canRemoveReview, isFalse);
    });

    test('falha na denúncia devolve mensagem e não altera o item', () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);
      final state = await container.read(adminReportsViewModelProvider.future);
      repository.failWith = const NetworkFailure('Sem conexão.');

      final error = await container
          .read(adminReportsViewModelProvider.notifier)
          .removeReview(state.reports.single);

      expect(error, 'Sem conexão.');
      expect(
        container
            .read(adminReportsViewModelProvider)
            .requireValue
            .reports
            .single
            .status,
        ReportStatus.pending,
      );
    });

    test('loadMore não consulta quando não há próxima página', () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);
      await container.read(adminReportsViewModelProvider.future);

      await container.read(adminReportsViewModelProvider.notifier).loadMore();

      expect(repository.lastCursor, isNull);
    });
  });
}
