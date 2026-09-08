// Horário de funcionamento editável pelo dono do posto.
//
// Formato no Firestore (`public_stations.openingHours`): mapa com as 7 chaves
// `monday`..`sunday`, cada uma `{ open: "HH:mm", close: "HH:mm" }` ou `null`
// (dia fechado). Ver SCHEMA-FIRESTORE.md.

enum Weekday {
  monday('monday', 'Segunda'),
  tuesday('tuesday', 'Terça'),
  wednesday('wednesday', 'Quarta'),
  thursday('thursday', 'Quinta'),
  friday('friday', 'Sexta'),
  saturday('saturday', 'Sábado'),
  sunday('sunday', 'Domingo');

  const Weekday(this.wireKey, this.label);

  final String wireKey;
  final String label;
}

class DayHours {
  const DayHours({required this.open, required this.close});

  /// `"HH:mm"` em 24h.
  final String open;
  final String close;

  Map<String, String> toWire() => {'open': open, 'close': close};

  static DayHours? fromWire(Object? value) {
    if (value is! Map) return null;
    final open = value['open'];
    final close = value['close'];
    if (open is! String || close is! String || open.isEmpty || close.isEmpty) {
      return null;
    }
    return DayHours(open: open, close: close);
  }

  DayHours copyWith({String? open, String? close}) =>
      DayHours(open: open ?? this.open, close: close ?? this.close);
}

/// Semana de funcionamento. Dia ausente do mapa interno = fechado.
class WeeklyHours {
  const WeeklyHours(this._byDay);
  const WeeklyHours.empty() : _byDay = const {};

  final Map<Weekday, DayHours> _byDay;

  DayHours? forDay(Weekday day) => _byDay[day];
  bool isOpen(Weekday day) => _byDay.containsKey(day);
  bool get anyInformed => _byDay.isNotEmpty;

  /// Retorna uma cópia com [day] definido (ou removido, se [hours] é `null`).
  WeeklyHours withDay(Weekday day, DayHours? hours) {
    final next = Map<Weekday, DayHours>.from(_byDay);
    if (hours == null) {
      next.remove(day);
    } else {
      next[day] = hours;
    }
    return WeeklyHours(next);
  }

  /// Aplica [hours] a todos os dias (usado pelo "copiar para todos").
  WeeklyHours filledWith(DayHours hours) =>
      WeeklyHours({for (final day in Weekday.values) day: hours});

  /// Mapa do Firestore: as 7 chaves sempre presentes, `null` para dia fechado.
  Map<String, dynamic> toWire() => {
    for (final day in Weekday.values) day.wireKey: _byDay[day]?.toWire(),
  };

  static WeeklyHours fromWire(Object? value) {
    if (value is! Map) return const WeeklyHours.empty();
    final byDay = <Weekday, DayHours>{};
    for (final day in Weekday.values) {
      final parsed = DayHours.fromWire(value[day.wireKey]);
      if (parsed != null) byDay[day] = parsed;
    }
    return WeeklyHours(byDay);
  }

  @override
  bool operator ==(Object other) {
    if (other is! WeeklyHours) return false;
    if (other._byDay.length != _byDay.length) return false;
    for (final entry in _byDay.entries) {
      final o = other._byDay[entry.key];
      if (o == null ||
          o.open != entry.value.open ||
          o.close != entry.value.close) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _byDay.entries.map((e) => Object.hash(e.key, e.value.open, e.value.close)),
  );
}
