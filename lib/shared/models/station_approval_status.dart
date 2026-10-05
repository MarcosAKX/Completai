// Situação de um posto na fila de aprovação do administrador.
//
// Vive em `public_stations/{uid}.status`, gravado como `pending` no cadastro
// e alterado só pelo admin (as rules impedem o dono de mexer). Documento
// anterior a este campo não tem `status`: é tratado como aprovado, para que
// nenhum posto já listado desapareça da Home.
enum StationApprovalStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const StationApprovalStatus(this.wireValue);

  final String wireValue;

  /// Ausente ou desconhecido = aprovado (posto legado).
  static StationApprovalStatus fromWire(Object? value) {
    if (value is! String || value.isEmpty) return approved;
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    return approved;
  }

  bool get isVisibleToDrivers => this == approved;

  String get label => switch (this) {
    pending => 'Aguardando aprovação',
    approved => 'Aprovado',
    rejected => 'Recusado',
  };
}
