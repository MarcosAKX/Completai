// Testa as escritas reais do serviço contra Firestore em memória (não valida rules).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:completai/core/errors/exceptions.dart';
import 'package:completai/features/auth/data/services/address_geocoding_service.dart';
import 'package:completai/features/auth/data/services/auth_profile_service.dart';
import 'package:completai/features/auth/domain/models/station_registration.dart';

class TestGeocoding extends AddressGeocodingService {
  bool fail = false;
  int calls = 0;
  @override
  Future<StationCoordinates> resolve(String address) async {
    calls++;
    if (fail) throw const ValidationException('Endereço não encontrado.');
    return const StationCoordinates(
      -20.949,
      -48.479,
      'SP',
      'Ribeirão Preto',
      'ribeirao preto',
    );
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late TestGeocoding geocoding;
  late AuthProfileService service;
  const station = StationRegistration(
    cnpj: '12345678000190',
    brandName: 'Posto Teste',
    phone: '(17) 3333-4444',
    address: 'Rua Teste, 100',
    neighborhood: 'Centro',
    city: 'Ribeirão Preto',
  );
  setUp(() {
    firestore = FakeFirebaseFirestore();
    geocoding = TestGeocoding();
    service = AuthProfileService(firestore, geocoding);
  });

  test(
    'cliente existente impede cadastro de posto antes da geocodificação',
    () async {
      await service.createClient(
        uid: 'u1',
        email: 'a@b.com',
        name: 'Ana',
        phone: '(17) 99999-9999',
      );
      await expectLater(
        service.createStation(
          uid: 'u1',
          email: 'a@b.com',
          registration: station,
        ),
        throwsA(isA<RoleConflictException>()),
      );
      expect(
        (await firestore.collection('gas_stations').doc('u1').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.collection('public_stations').doc('u1').get()).exists,
        isFalse,
      );
      expect(geocoding.calls, 0);
    },
  );

  test('posto existente impede cadastro de cliente', () async {
    await service.createStation(
      uid: 'u1',
      email: 'a@b.com',
      registration: station,
    );
    await expectLater(
      service.createClient(
        uid: 'u1',
        email: 'a@b.com',
        name: 'Ana',
        phone: '(17) 99999-9999',
      ),
      throwsA(isA<RoleConflictException>()),
    );
    expect(
      (await firestore.collection('users').doc('u1').get()).exists,
      isFalse,
    );
  });

  test(
    'geocodificação com falha não salva nenhum documento de posto',
    () async {
      geocoding.fail = true;
      await expectLater(
        service.createStation(
          uid: 'u1',
          email: 'a@b.com',
          registration: station,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        (await firestore.collection('gas_stations').doc('u1').get()).exists,
        isFalse,
      );
      expect(
        (await firestore.collection('public_stations').doc('u1').get()).exists,
        isFalse,
      );
    },
  );

  test('cadastro grava schema público completo sem dados sensíveis', () async {
    await service.createStation(
      uid: 'u1',
      email: 'a@b.com',
      registration: station,
    );
    final private = (await firestore.collection('gas_stations').doc('u1').get())
        .data()!;
    final public =
        (await firestore.collection('public_stations').doc('u1').get()).data()!;
    expect(private.keys.toSet(), {
      'uid',
      'type',
      'cnpj',
      'email',
      'phone',
      'brandName',
      'createdAt',
      'updatedAt',
    });
    expect(public.keys.toSet(), {
      'uid',
      'brandName',
      'address',
      'neighborhood',
      'city',
      'citySearchKey',
      'state',
      'latitude',
      'longitude',
      'prices',
      'pricesUpdatedAt',
      'openingHours',
      'averageRating',
      'reviewCount',
      'services',
      'tags',
    });
    expect(public['city'], 'Ribeirão Preto');
    expect(public['citySearchKey'], 'ribeirao preto');
    expect(public['state'], 'SP');
    expect(public['neighborhood'], 'Centro');
    expect(public['latitude'], -20.949);
    expect(public['longitude'], -48.479);
    expect(public['prices'], {
      'gasolineRegular': null,
      'gasolineAdditive': null,
      'ethanol': null,
      'dieselS10': null,
      'dieselS500': null,
    });
    expect(public['openingHours'], {
      'monday': null,
      'tuesday': null,
      'wednesday': null,
      'thursday': null,
      'friday': null,
      'saturday': null,
      'sunday': null,
    });
    expect(public['reviewCount'], 0);
    expect(private['createdAt'], isA<Timestamp>());
    expect(private['phone'], '(17) 3333-4444');
    expect(geocoding.calls, 1);
  });

  test(
    'cadastro repetido do mesmo papel é idempotente e não sobrescreve',
    () async {
      await service.createClient(
        uid: 'u1',
        email: 'a@b.com',
        name: 'Ana',
        phone: '(17) 99999-9999',
      );
      await service.createClient(
        uid: 'u1',
        email: 'a@b.com',
        name: 'Outro',
        phone: '(17) 98888-8888',
      );
      expect(
        (await firestore.collection('users').doc('u1').get()).data()!['name'],
        'Ana',
      );
    },
  );

  test('leitura rejeita estado legado com dois papéis', () async {
    await firestore.collection('users').doc('u1').set({
      'uid': 'u1',
      'type': 'client',
    });
    await firestore.collection('gas_stations').doc('u1').set({
      'uid': 'u1',
      'type': 'gas_station',
    });
    await expectLater(
      service.readRole('u1'),
      throwsA(isA<RoleConflictException>()),
    );
  });
}
