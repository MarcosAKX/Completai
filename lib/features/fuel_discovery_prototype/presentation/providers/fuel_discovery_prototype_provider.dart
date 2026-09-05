// Provider exclusivo do protótipo, removível junto com a feature experimental.
import 'package:riverpod/riverpod.dart';

import '../viewmodels/fuel_discovery_prototype_viewmodel.dart';

final fuelDiscoveryPrototypeProvider =
    NotifierProvider<
      FuelDiscoveryPrototypeViewModel,
      FuelDiscoveryPrototypeState
    >(FuelDiscoveryPrototypeViewModel.new);
