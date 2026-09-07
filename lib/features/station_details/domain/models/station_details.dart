// Modelo público completo de um posto, sem qualquer dado administrativo.
import '../../../../shared/models/station_brand.dart';
import '../../../../shared/models/station_fuel.dart';

class StationOpeningPeriod {
  const StationOpeningPeriod({required this.open, required this.close});

  final String open;
  final String close;
}

class StationDetails {
  const StationDetails({
    required this.uid,
    required this.name,
    required this.brand,
    required this.address,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.prices,
    required this.pricesUpdatedAt,
    required this.openingHours,
    required this.averageRating,
    required this.reviewCount,
    required this.services,
  });

  final String uid;
  final String name;
  final StationBrand brand;
  final String address;
  final String neighborhood;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final Map<StationFuel, double?> prices;
  final DateTime? pricesUpdatedAt;
  final Map<String, StationOpeningPeriod?> openingHours;
  final double averageRating;
  final int reviewCount;
  final List<String> services;

  double? priceFor(StationFuel fuel) => prices[fuel];
}
