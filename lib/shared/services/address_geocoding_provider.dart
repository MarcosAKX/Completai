// Provider único do serviço de geocodificação compartilhado.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'address_geocoding_service.dart';

final addressGeocodingServiceProvider = Provider<AddressGeocodingService>(
  (ref) => AddressGeocodingService(),
);
