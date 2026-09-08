// Serviços/comodidades sugeridos na aba "Informações". O dono liga/desliga
// estes; qualquer serviço já salvo que não esteja aqui também aparece
// (marcado) para não sumir.
const List<String> kSuggestedServices = [
  'Conveniência',
  'Calibragem',
  'Ar e água',
  'Troca de óleo',
  'Lava-rápido',
  'Borracharia',
  'GNV',
  'Banheiro',
  'Wi-Fi',
  'Caixa eletrônico',
  'Lanchonete',
  'Estacionamento',
];

/// Teto imposto pelas `firestore.rules` para `services` e `tags`.
const int kMaxStationServices = 20;
const int kMaxStationTags = 20;
