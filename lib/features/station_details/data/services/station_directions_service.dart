// Abre o posto no aplicativo de mapas do aparelho.
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/exceptions.dart';

class StationDirectionsService {
  const StationDirectionsService();

  Future<void> open({
    required String address,
    required String neighborhood,
    required String city,
    required String state,
    required double latitude,
    required double longitude,
  }) async {
    final query = buildQuery(
      address: address,
      neighborhood: neighborhood,
      city: city,
      state: state,
      latitude: latitude,
      longitude: longitude,
    );
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(query)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw const ValidationException(
        'Não foi possível abrir o aplicativo de mapas.',
      );
    }
  }

  /// Manda o endereço em texto, não a coordenada gravada.
  ///
  /// O OpenStreetMap tem quase nenhum número de porta no interior de SP
  /// (Bebedouro inteira tem 39 objetos com `addr:housenumber`), então a
  /// coordenada que gravamos é o centro da via, não o portão do posto. O
  /// Google Maps tem esses números e resolve o texto corretamente.
  ///
  /// A coordenada continua sendo o destino quando não há endereço utilizável
  /// — documento antigo ou malformado.
  static String buildQuery({
    required String address,
    required String neighborhood,
    required String city,
    required String state,
    required double latitude,
    required double longitude,
  }) {
    final parts = [address, neighborhood, city, state]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '$latitude,$longitude';
    return [...parts, 'Brasil'].join(', ');
  }
}
