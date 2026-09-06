// Bandeira do posto — identidade exibida ao cliente na listagem e no detalhe.
//
// Guardada como string em `public_stations.brand` (ver SCHEMA-FIRESTORE.md).
// Domínio puro: sem cor/ícone aqui, isso é decisão de apresentação.
enum StationBrand {
  shell('shell', 'Shell'),
  ipiranga('ipiranga', 'Ipiranga'),
  petrobras('petrobras', 'Petrobras'),
  ale('ale', 'Ale'),
  raizen('raizen', 'Raízen'),
  branca('branca', 'Bandeira branca'),
  outra('outra', 'Outra');

  const StationBrand(this.wireValue, this.label);

  /// Valor persistido em `public_stations.brand`.
  final String wireValue;

  /// Rótulo exibido no seletor e no selo.
  final String label;

  /// Converte o valor do Firestore de volta para o enum. Valor ausente ou
  /// desconhecido cai em [StationBrand.branca] (posto sem bandeira definida).
  static StationBrand fromWire(Object? value) {
    for (final brand in StationBrand.values) {
      if (brand.wireValue == value) return brand;
    }
    return StationBrand.branca;
  }
}
