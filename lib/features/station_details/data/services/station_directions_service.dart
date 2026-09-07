// Abre coordenadas públicas do posto no aplicativo de mapas do aparelho.
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/exceptions.dart';

class StationDirectionsService {
  const StationDirectionsService();

  Future<void> open(double latitude, double longitude) async {
    final destination = Uri.encodeComponent('$latitude,$longitude');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$destination',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw const ValidationException(
        'Não foi possível abrir o aplicativo de mapas.',
      );
    }
  }
}
