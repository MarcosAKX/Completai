// Estado das abas de postos: a fila de pendentes e os já listados.
import 'admin_station.dart';

class AdminStationsState {
  const AdminStationsState({
    required this.pending,
    required this.listed,
    this.invalidDocumentPaths = const [],
  });

  const AdminStationsState.empty() : pending = const [], listed = const [], invalidDocumentPaths = const [];

  /// Aguardando aprovação, mais antigos primeiro — quem esperou mais aparece
  /// em cima.
  final List<AdminStation> pending;

  /// Aprovados e recusados, já revisados.
  final List<AdminStation> listed;

  /// Documentos que não puderam ser lidos; registrados em vez de engolidos.
  final List<String> invalidDocumentPaths;

  int get pendingCount => pending.length;

  AdminStationsState copyWith({
    List<AdminStation>? pending,
    List<AdminStation>? listed,
    List<String>? invalidDocumentPaths,
  }) => AdminStationsState(
    pending: pending ?? this.pending,
    listed: listed ?? this.listed,
    invalidDocumentPaths: invalidDocumentPaths ?? this.invalidDocumentPaths,
  );
}
