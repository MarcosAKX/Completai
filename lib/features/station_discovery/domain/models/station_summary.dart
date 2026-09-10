// Dados públicos necessários para listar e comparar postos.
import '../../../../shared/models/station_brand.dart';
import '../../../../shared/models/station_opening_period.dart';

enum FuelType { gasoline, ethanol, diesel }

class StationSummary {
  const StationSummary({
    required this.uid,
    required this.name,
    required this.brand,
    required this.neighborhood,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.prices,
    required this.averageRating,
    required this.reviewCount,
    required this.pricesUpdatedAt,
    required this.openingHours,
    this.distanceKm,
  });
  final String uid;
  final String name;
  final StationBrand brand;
  final String neighborhood;
  final String city;
  final double latitude;
  final double longitude;
  final Map<FuelType, double?> prices;
  final double averageRating;
  final int reviewCount;
  final DateTime? pricesUpdatedAt;
  final Map<String, StationOpeningPeriod?> openingHours;
  final double? distanceKm;

  double? priceFor(FuelType fuel) => prices[fuel];
  StationSummary withDistance(double value) => StationSummary(
    uid: uid,
    name: name,
    brand: brand,
    neighborhood: neighborhood,
    city: city,
    latitude: latitude,
    longitude: longitude,
    prices: prices,
    averageRating: averageRating,
    reviewCount: reviewCount,
    pricesUpdatedAt: pricesUpdatedAt,
    openingHours: openingHours,
    distanceKm: value,
  );
}
