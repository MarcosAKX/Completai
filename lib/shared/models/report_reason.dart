// Motivos de denúncia de avaliação — lista fechada, não texto livre.
//
// Os `wireValue` são validados nas `firestore.rules` (create de
// `.../reviews/{clientUid}/reports/{reporterUid}`). Acrescentar um valor aqui
// sem acrescentar na rule faz a denúncia ser recusada com permission-denied.
enum ReportReason {
  offensive('offensive'),
  fake('fake'),
  offTopic('off_topic'),
  spam('spam'),
  personalData('personal_data'),
  other('other');

  const ReportReason(this.wireValue);

  final String wireValue;

  static ReportReason fromWire(Object? value) {
    if (value is String) {
      for (final reason in values) {
        if (reason.wireValue == value) return reason;
      }
    }
    return other;
  }

  String get label => switch (this) {
    offensive => 'Linguagem ofensiva',
    fake => 'Avaliação falsa',
    offTopic => 'Não é sobre este posto',
    spam => 'Spam ou propaganda',
    personalData => 'Expõe dado pessoal',
    other => 'Outro motivo',
  };

  String get description => switch (this) {
    offensive => 'Xingamento, ameaça ou discurso de ódio.',
    fake => 'Cliente não esteve no posto ou inventou o relato.',
    offTopic => 'O relato é de outro estabelecimento.',
    personalData => 'Cita telefone, endereço ou nome de funcionário.',
    spam => 'Divulga outro negócio ou link.',
    other => 'Nenhuma das opções acima.',
  };
}
