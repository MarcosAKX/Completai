// Área atendida pelo app. Durante o MVP é uma cidade só: o cadastro e o
// perfil do posto gravam exatamente `primaryCity`, e o seletor manual da
// home oferece `cities`. A geocodificação continua confirmando SP em ambos
// os fluxos — esta constante restringe a escolha, não substitui a validação.
abstract final class ServiceArea {
  static const primaryCity = 'Bebedouro';

  /// Cidades oferecidas ao motorista no seletor manual da home.
  static const cities = [primaryCity];
}
