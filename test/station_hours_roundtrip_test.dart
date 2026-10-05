// O horário salvo no painel precisa chegar ao cliente como "aberto agora".
//
// Reproduz o trajeto inteiro contra o Firestore: o dono salva pela aba
// Horários, o documento vai para `public_stations`, e as três telas que
// mostram funcionamento leem de volta — prévia do painel, listagem da Home e
// detalhe público. Teste de caminho completo porque cada ponta faz o próprio
// parse: o painel com `WeeklyHours.fromWire`, a Home com `_period`.
import 'package:completai/features/station_details/data/services/station_details_service.dart';
import 'package:completai/features/station_discovery/data/services/public_station_service.dart';
import 'package:completai/features/station_discovery/domain/station_opening_hours.dart';
import 'package:completai/features/station_panel/data/services/station_panel_service.dart';
import 'package:completai/features/station_panel/domain/models/opening_hours.dart';
import 'package:completai/shared/models/station_hours_status.dart';
import 'package:completai/shared/services/address_geocoding_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubGeocoding extends AddressGeocodingService {
  @override
  Future<StationCoordinates> resolve(StationAddressInput input) async =>
      const StationCoordinates(-20.9, -48.4, 'SP', 'Bebedouro', 'bebedouro');
}

const _uid = 'posto-1';

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
    'address': 'Rua Um, 100',
    'neighborhood': 'Centro',
    'city': 'Bebedouro',
    'citySearchKey': 'bebedouro',
    'state': 'SP',
    'latitude': -20.9,
    'longitude': -48.4,
    'prices': const {
      'gasolineRegular': 6.29,
      'gasolineAdditive': null,
      'ethanol': null,
      'dieselS10': null,
      'dieselS500': null,
    },
    'openingHours': const {'monday': null},
    'averageRating': 0.0,
    'reviewCount': 0,
    'services': const <String>[],
    'tags': const <String>[],
    'status': 'approved',
  });
  return firestore;
}

void main() {
  // 04/10/2026 é domingo. 21:07, dentro de um expediente que fecha às 23:00.
  final domingoNoite = DateTime(2026, 10, 4, 21, 7);

  test('08:00-23:00 nos 7 dias: salvo no painel, aberto nas três telas', () async {
    final firestore = await _seeded();
    final panel = StationPanelService(firestore, _StubGeocoding());

    // Exatamente o que o "copiar p/ todos" produz.
    final hours = const WeeklyHours.empty().filledWith(
      const DayHours(open: '08:00', close: '23:00'),
    );
    await panel.writeOpeningHours(_uid, hours);

    // 1) Prévia do painel: relê o perfil e converte.
    final profile = await panel.read(_uid);
    final naPrevia = stationHoursStatus(
      domingoNoite,
      profile.openingHours.toOpeningPeriods(),
    );
    expect(naPrevia.isOpen, isTrue, reason: 'prévia do painel');
    expect(naPrevia.label, 'Aberto agora até 23:00');

    // 2) Listagem da Home: parse próprio, por isso entra no teste.
    final summary = (await PublicStationService(
      firestore,
    ).fetchByCityKey('bebedouro')).single;
    expect(
      isStationOpen(domingoNoite, summary.openingHours),
      isTrue,
      reason: 'card da Home',
    );

    // 3) Detalhe público.
    final details = await StationDetailsService(firestore).readStation(_uid);
    expect(
      stationHoursStatus(domingoNoite, details.openingHours).isOpen,
      isTrue,
      reason: 'detalhe público',
    );
  });

  test('mapa aninhado sem tipo (como o aparelho real devolve) ainda abre', () async {
    // O `cloud_firestore` devolve mapa ANINHADO como `Map<Object?, Object?>`
    // no aparelho: o tipo se perde no canal de plataforma. A checagem estrita
    // `is! Map<String, dynamic>` rejeitava, todo dia virava null e o posto
    // aparecia fechado com o horario certo gravado. O FakeFirebaseFirestore
    // devolve o tipo limpo, entao so um documento montado a mao pega isto.
    final firestore = await _seeded();
    final semTipo = <Object?, Object?>{
      for (final day in stationWeekdayKeys)
        day: <Object?, Object?>{'open': '08:00', 'close': '23:00'},
    };
    await firestore.collection('public_stations').doc(_uid).update({
      'openingHours': semTipo,
    });

    final summary = (await PublicStationService(
      firestore,
    ).fetchByCityKey('bebedouro')).single;
    expect(
      isStationOpen(domingoNoite, summary.openingHours),
      isTrue,
      reason: 'card da Home com mapa sem parametrizacao',
    );

    final details = await StationDetailsService(firestore).readStation(_uid);
    expect(
      stationHoursStatus(domingoNoite, details.openingHours).isOpen,
      isTrue,
      reason: 'detalhe publico com mapa sem parametrizacao',
    );
  });

  test('o documento guarda os 7 dias, nenhum nulo', () async {
    final firestore = await _seeded();
    final panel = StationPanelService(firestore, _StubGeocoding());

    await panel.writeOpeningHours(
      _uid,
      const WeeklyHours.empty().filledWith(
        const DayHours(open: '08:00', close: '23:00'),
      ),
    );

    final gravado =
        (await firestore.collection('public_stations').doc(_uid).get())
                .data()!['openingHours']
            as Map<String, dynamic>;

    for (final day in stationWeekdayKeys) {
      expect(
        gravado[day],
        {'open': '08:00', 'close': '23:00'},
        reason: '$day deveria estar gravado',
      );
    }
  });

  test('salvar só alguns dias não apaga nem inventa os outros', () async {
    final firestore = await _seeded();
    final panel = StationPanelService(firestore, _StubGeocoding());

    await panel.writeOpeningHours(
      _uid,
      const WeeklyHours.empty().withDay(
        Weekday.sunday,
        const DayHours(open: '08:00', close: '23:00'),
      ),
    );

    final profile = await panel.read(_uid);
    expect(profile.openingHours.isOpen(Weekday.sunday), isTrue);
    expect(profile.openingHours.isOpen(Weekday.monday), isFalse);
    expect(
      stationHoursStatus(
        domingoNoite,
        profile.openingHours.toOpeningPeriods(),
      ).isOpen,
      isTrue,
    );
  });
}
