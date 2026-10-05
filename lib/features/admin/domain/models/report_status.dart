// Situação de uma denúncia depois que o admin olhou.
//
// Gravado em `.../reports/{reporterUid}.status`. Ausente = pendente, porque
// quem cria a denúncia é o dono do posto e ele não define situação.
enum ReportStatus {
  pending('pending'),
  resolved('resolved'),
  dismissed('dismissed');

  const ReportStatus(this.wireValue);

  final String wireValue;

  static ReportStatus fromWire(Object? value) {
    if (value is! String || value.isEmpty) return pending;
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    return pending;
  }

  String get label => switch (this) {
    pending => 'Aguardando análise',
    resolved => 'Avaliação removida',
    dismissed => 'Denúncia descartada',
  };
}
