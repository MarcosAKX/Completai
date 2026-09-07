// Combustíveis públicos compartilhados pelo painel do dono e pelo detalhe.
enum StationFuel {
  gasolineRegular('gasolineRegular', 'Gasolina comum'),
  gasolineAdditive('gasolineAdditive', 'Gasolina aditivada'),
  ethanol('ethanol', 'Etanol'),
  dieselS10('dieselS10', 'Diesel S10'),
  dieselS500('dieselS500', 'Diesel S500');

  const StationFuel(this.wireKey, this.label);

  final String wireKey;
  final String label;
}
