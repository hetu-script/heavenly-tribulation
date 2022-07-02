import 'package:samsara/event.dart';
import 'package:hetu_script/values.dart';

abstract class CustomEvents extends Events {
  static const back2menu = 'back2menu';
  static const incidentOccurred = 'incident_occurred';
}

class MenuEvent extends GameEvent {
  const MenuEvent.back2menu({super.scene})
      : super(name: CustomEvents.back2menu);
}

class HistoryEvent extends GameEvent {
  final HTStruct incidentData;

  const HistoryEvent({
    required super.name,
    required this.incidentData,
  });

  const HistoryEvent.occurred({required HTStruct incidentData})
      : this(name: CustomEvents.incidentOccurred, incidentData: incidentData);
}
