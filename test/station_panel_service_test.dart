// Serviço do painel: leitura combinada e escrita coerente nas duas coleções.
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/features/station_panel/data/services/station_panel_service.dart';
import 'package:completai/features/station_panel/domain/models/opening_hours.dart';
import 'package:completai/features/station_panel/domain/models/station_fuel.dart';
import 'package:completai/shared/models/station_brand.dart';
import 'package:completai/shared/services/address_geocoding_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

const _uid = 'station-1';

Future<FakeFirebaseFirestore> _seeded() async {
  final firestore = FakeFirebaseFirestore();
  await firestore.collection('gas_stations').doc(_uid).set({
    'uid': _uid,
    'type': 'gas_station',
    'cnpj': '12345678000190',
    'email': 'posto@example.test',
    'phone': '(17) 3333-4444',
    'brandName': 'Posto Teste',
  });
  await firestore.collection('public_stations').doc(_uid).set({
    'uid': _uid,
    'brandName': 'Posto Teste',
    'address': 'Rua 1, 100',
    'neighborhood': 'Centro',
    'city': 'Bebedouro',
    'citySearchKey': 'bebedouro',
    'state': 'SP',
    'latitude': -20.9,
    'longitude': -48.4,
    'prices': {
      'gasolineRegular': 6.29,
      'gasolineAdditive': null,
      'ethanol': null,
      'dieselS10': null,
      'dieselS500': null,
    },
    'openingHours': {'monday': null},
    'services': ['calibragem', 'conveniência'],
    'tags': <String>[],
  });
  return firestore;
}

AddressGeocodingService _geocoding() => AddressGeocodingService.forTesting(
  (_) async => [
    Location(latitude: -20.5, longitude: -48.5, timestamp: DateTime(2026)),
  ],
  (_) async => [
    Placemark(
      administrativeArea: 'São Paulo',
      locality: 'Barretos',
      subAdministrativeArea: 'Barretos',
    ),
  ],
);

void main() {
  test('lê perfil unindo dados privados e públicos', () async {
    final firestore = await _seeded();
    final service = StationPanelService(firestore, _geocoding());

    final profile = await service.read(_uid);

    expect(profile.cnpj, '12345678000190');
    expect(profile.priceFor(StationFuel.gasolineRegular), 6.29);
    expect(profile.priceFor(StationFuel.ethanol), isNull);
    expect(profile.serviceCount, 2);
    expect(profile.brand, StationBrand.branca);
  });

  test('publica preços altera só o mapa prices e o carimbo', () async {
    final firestore = await _seeded();
    final service = StationPanelService(firestore, _geocoding());

    await service.writePrices(_uid, {StationFuel.ethanol: 3.999});

    final data = (await firestore.collection('public_stations').doc(_uid).get())
        .data()!;
    expect((data['prices'] as Map)['ethanol'], 3.999);
    expect((data['prices'] as Map)['gasolineRegular'], 6.29);
    expect(data['pricesUpdatedAt'], isNotNull);
  });

  test('renomear grava nas duas coleções', () async {
    final firestore = await _seeded();
    final service = StationPanelService(firestore, _geocoding());

    await service.writeIdentity(_uid, 'Novo Nome', '(17) 90000-0000');

    final private = (await firestore.collection('gas_stations').doc(_uid).get())
        .data()!;
    final public =
        (await firestore.collection('public_stations').doc(_uid).get()).data()!;
    expect(private['brandName'], 'Novo Nome');
    expect(private['phone'], '(17) 90000-0000');
    expect(public['brandName'], 'Novo Nome');
  });

  test('novo endereço regrava cidade canônica da geocodificação', () async {
    final firestore = await _seeded();
    final service = StationPanelService(firestore, _geocoding());

    await service.writeAddress(_uid, 'Av. Nova, 200', 'Jardim', 'barretos');

    final data = (await firestore.collection('public_stations').doc(_uid).get())
        .data()!;
    expect(data['city'], 'Barretos');
    expect(data['citySearchKey'], 'barretos');
    expect(data['state'], 'SP');
  });

  test('bandeira é persistida em public_stations', () async {
    final firestore = await _seeded();
    final service = StationPanelService(firestore, _geocoding());

    await service.writeBrand(_uid, StationBrand.shell);

    final data = (await firestore.collection('public_stations').doc(_uid).get())
        .data()!;
    expect(data['brand'], 'shell');
  });

  test('lê serviços, marcadores e horários', () async {
    final firestore = await _seeded();
    await firestore.collection('public_stations').doc(_uid).update({
      'tags': ['24 horas'],
      'openingHours': {
        'monday': {'open': '08:00', 'close': '18:00'},
      },
    });
    final profile = await StationPanelService(firestore, _geocoding()).read(_uid);

    expect(profile.services, ['calibragem', 'conveniência']);
    expect(profile.tags, ['24 horas']);
    expect(profile.openingHours.isOpen(Weekday.monday), isTrue);
    expect(profile.openingHours.forDay(Weekday.monday)!.close, '18:00');
  });

  test('writeInfo grava serviços e marcadores em public_stations', () async {
    final firestore = await _seeded();
    final service = StationPanelService(firestore, _geocoding());

    await service.writeInfo(_uid, ['Conveniência', 'GNV'], ['rodovia']);

    final data = (await firestore.collection('public_stations').doc(_uid).get())
        .data()!;
    expect(data['services'], ['Conveniência', 'GNV']);
    expect(data['tags'], ['rodovia']);
  });

  test('writeInfo rejeita mais de 20 serviços antes de escrever', () async {
    final service = StationPanelService(await _seeded(), _geocoding());
    expect(
      () => service.writeInfo(
        _uid,
        List.generate(21, (i) => 'servico $i'),
        const [],
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('writeOpeningHours grava as 7 chaves', () async {
    final firestore = await _seeded();
    final service = StationPanelService(firestore, _geocoding());

    await service.writeOpeningHours(
      _uid,
      const WeeklyHours.empty().withDay(
        Weekday.friday,
        const DayHours(open: '06:00', close: '22:00'),
      ),
    );

    final hours = (await firestore.collection('public_stations').doc(_uid).get())
        .data()!['openingHours'] as Map;
    expect(hours.keys.length, 7);
    expect(hours['friday'], {'open': '06:00', 'close': '22:00'});
    expect(hours['monday'], isNull);
  });
}
