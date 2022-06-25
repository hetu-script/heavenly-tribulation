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
  final HTStruct data;

  const HistoryEvent({
    required super.name,
    required this.data,
  });

  const HistoryEvent.occurred({required HTStruct data})
      : this(name: CustomEvents.incidentOccurred, data: data);
}
