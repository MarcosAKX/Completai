// Enums de admin: valores do wire e tolerância a documento legado.
import 'package:completai/shared/models/report_reason.dart';
import 'package:completai/features/admin/domain/models/report_status.dart';
import 'package:completai/shared/models/station_approval_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StationApprovalStatus', () {
    test('documento sem status é tratado como aprovado', () {
      // Garantia central da migração: posto cadastrado antes do campo não
      // pode desaparecer da Home.
      for (final value in [null, '', 'desconhecido', 42]) {
        expect(
          StationApprovalStatus.fromWire(value),
          StationApprovalStatus.approved,
          reason: 'valor $value deveria cair em approved',
        );
      }
    });

    test('só aprovado é visível para o motorista', () {
      expect(StationApprovalStatus.approved.isVisibleToDrivers, isTrue);
      expect(StationApprovalStatus.pending.isVisibleToDrivers, isFalse);
      expect(StationApprovalStatus.rejected.isVisibleToDrivers, isFalse);
    });

    test('ida e volta pelo wireValue', () {
      for (final status in StationApprovalStatus.values) {
        expect(StationApprovalStatus.fromWire(status.wireValue), status);
      }
    });
  });

  group('ReportReason', () {
    // Estes valores estão escritos à mão nas firestore.rules. Se este teste
    // falhar, a rule também precisa mudar, senão a denúncia volta como
    // permission-denied.
    test('wireValues batem com a lista das rules', () {
      expect(ReportReason.values.map((r) => r.wireValue).toList(), const [
        'offensive',
        'fake',
        'off_topic',
        'spam',
        'personal_data',
        'other',
      ]);
    });

    test('valor desconhecido cai em other', () {
      expect(ReportReason.fromWire('texto livre'), ReportReason.other);
      expect(ReportReason.fromWire(null), ReportReason.other);
    });

    test('todo motivo tem rótulo e descrição', () {
      for (final reason in ReportReason.values) {
        expect(reason.label, isNotEmpty);
        expect(reason.description, isNotEmpty);
      }
    });
  });

  group('ReportStatus', () {
    test('ausente é pendente — quem denuncia não define situação', () {
      expect(ReportStatus.fromWire(null), ReportStatus.pending);
      expect(ReportStatus.fromWire(''), ReportStatus.pending);
    });

    test('ida e volta pelo wireValue', () {
      for (final status in ReportStatus.values) {
        expect(ReportStatus.fromWire(status.wireValue), status);
      }
    });
  });
}
