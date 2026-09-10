// Calcula o status atual, incluindo horários que atravessam meia-noite.
import '../../../shared/models/station_hours_status.dart';
import '../../../shared/models/station_opening_period.dart';

bool isStationOpen(DateTime now, Map<String, StationOpeningPeriod?> hours) =>
    stationHoursStatus(now, hours).isOpen;
