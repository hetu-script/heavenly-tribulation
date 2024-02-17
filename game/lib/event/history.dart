import 'package:samsara/event.dart';
import 'package:hetu_script/values.dart';

abstract class HistoryEvents {
  static const incidentOccurred = 'incident_occurred';
}

class HistoryEvent extends GameEvent {
  final HTStruct incidentData;

  const HistoryEvent({
    required super.name,
    required this.incidentData,
  });

  const HistoryEvent.occurred({required HTStruct incidentData})
      : this(name: HistoryEvents.incidentOccurred, incidentData: incidentData);
}
