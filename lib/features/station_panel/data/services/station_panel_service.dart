// Leitura e escrita do perfil do posto. Nome e endereço tocam as duas
// coleções e vão em batch; preços e bandeira são só públicos.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/services/address_geocoding_service.dart';
import '../../../../shared/models/station_brand.dart';
import '../../domain/models/opening_hours.dart';
import '../../domain/models/station_fuel.dart';
import '../../domain/models/station_profile.dart';
import '../../domain/station_service_options.dart';

class StationPanelService {
  StationPanelService(this._firestore, this._geocoding);
  final FirebaseFirestore _firestore;
  final AddressGeocodingService _geocoding;

  DocumentReference<Map<String, dynamic>> _private(String uid) =>
      _firestore.collection(FirestoreCollections.gasStations).doc(uid);
  DocumentReference<Map<String, dynamic>> _public(String uid) =>
      _firestore.collection(FirestoreCollections.publicStations).doc(uid);

  Future<StationProfile> read(String uid) async {
    final documents = await Future.wait([
      _private(uid).get(const GetOptions(source: Source.server)),
      _public(uid).get(const GetOptions(source: Source.server)),
    ]);
    final private = documents[0].data();
    final public = documents[1].data();
    if (private == null || public == null) {
      throw const InvalidProfileException();
    }
    if (private['type'] != 'gas_station') {
      throw const InvalidProfileException();
    }

    final prices = (public['prices'] as Map<String, dynamic>?) ?? const {};
    double? price(String key) {
      final value = prices[key];
      return value is num ? value.toDouble() : null;
    }

    String str(Object? value, [String fallback = '']) =>
        value is String && value.isNotEmpty ? value : fallback;

    List<String> strList(Object? value) => (value is List)
        ? value.whereType<String>().where((s) => s.isNotEmpty).toList()
        : const [];

    return StationProfile(
      uid: uid,
      name: str(public['brandName'], str(private['brandName'])),
      cnpj: str(private['cnpj']),
      phone: str(private['phone']),
      email: str(private['email']),
      brand: StationBrand.fromWire(public['brand']),
      address: str(public['address']),
      neighborhood: str(public['neighborhood']),
      city: str(public['city']),
      state: str(public['state'], FirestoreCollections.defaultState),
      prices: {
        for (final fuel in StationFuel.values) fuel: price(fuel.wireKey),
      },
      services: strList(public['services']),
      tags: strList(public['tags']),
      openingHours: WeeklyHours.fromWire(public['openingHours']),
    );
  }

  Future<void> writePrices(String uid, Map<StationFuel, double?> prices) {
    return _public(uid).update({
      for (final entry in prices.entries)
        'prices.${entry.key.wireKey}': entry.value,
      'pricesUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> writeIdentity(String uid, String name, String phone) {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    if (trimmedName.isEmpty || trimmedPhone.isEmpty) {
      throw const ValidationException('Informe o nome e o telefone do posto.');
    }
    final batch = _firestore.batch()
      ..update(_private(uid), {
        'brandName': trimmedName,
        'phone': trimmedPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_public(uid), {'brandName': trimmedName});
    return batch.commit();
  }

  Future<void> writeAddress(
    String uid,
    String address,
    String neighborhood,
    String city,
  ) async {
    if (address.trim().isEmpty ||
        neighborhood.trim().isEmpty ||
        city.trim().isEmpty) {
      throw const ValidationException('Preencha endereço, bairro e cidade.');
    }
    final coordinates = await _geocoding.resolve(
      '${address.trim()}, ${neighborhood.trim()}, ${city.trim()}, Brasil',
    );
    await _public(uid).update({
      'address': address.trim(),
      'neighborhood': neighborhood.trim(),
      'city': coordinates.city,
      'citySearchKey': coordinates.citySearchKey,
      'state': coordinates.state,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
    });
  }

  Future<void> writeBrand(String uid, StationBrand brand) {
    return _public(uid).update({'brand': brand.wireValue});
  }

  Future<void> writeInfo(
    String uid,
    List<String> services,
    List<String> tags,
  ) {
    if (services.length > kMaxStationServices ||
        tags.length > kMaxStationTags) {
      throw const ValidationException(
        'Máximo de 20 serviços e 20 marcadores.',
      );
    }
    return _public(uid).update({'services': services, 'tags': tags});
  }

  Future<void> writeOpeningHours(String uid, WeeklyHours hours) {
    return _public(uid).update({'openingHours': hours.toWire()});
  }
}
