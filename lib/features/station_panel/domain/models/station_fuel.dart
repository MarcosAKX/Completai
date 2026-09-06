// Combustíveis editáveis pelo dono do posto.
//
// As chaves batem exatamente com o mapa `prices` de `public_stations`
// (ver SCHEMA-FIRESTORE.md). É uma lista mais completa do que o `FuelType`
// de `station_discovery`, que agrupa por tipo para a comparação do motorista.
enum StationFuel {
  gasolineRegular('gasolineRegular', 'Gasolina comum'),
  gasolineAdditive('gasolineAdditive', 'Gasolina aditivada'),
  ethanol('ethanol', 'Etanol'),
  dieselS10('dieselS10', 'Diesel S10'),
  dieselS500('dieselS500', 'Diesel S500');

  const StationFuel(this.wireKey, this.label);

  /// Nome do campo dentro do mapa `prices` no Firestore.
  final String wireKey;

  /// Rótulo exibido no formulário.
  final String label;
}
