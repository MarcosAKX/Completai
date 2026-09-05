// Modelo estritamente local do mockup; não representa leitura do Firestore.
import '../opening_hours.dart';

enum PrototypeFuel { gasoline, ethanol, diesel }

class FuelPrototypeStation {
  const FuelPrototypeStation({
    required this.name,
    required this.neighborhood,
    required this.city,
    required this.prices,
    required this.rating,
    required this.reviewCount,
    required this.pricesUpdatedAt,
    required this.openingHours,
  });

  final String name;
  final String neighborhood;
  final String city;
  final Map<PrototypeFuel, double> prices;
  final double rating;
  final int reviewCount;
  final DateTime pricesUpdatedAt;
  final DailyOpeningHours openingHours;

  double priceFor(PrototypeFuel fuel) => prices[fuel] ?? double.infinity;
}
