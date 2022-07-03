import 'package:samsara/event.dart';
import 'package:hetu_script/values.dart';

abstract class CustomEvents extends Events {
  static const back2menu = 'back_to_menu';
  static const dialogFinished = 'dialog_finished';
  static const incidentOccurred = 'incident_occurred';
}

class UIEvent extends GameEvent {
  const UIEvent.back2menu({super.scene}) : super(name: CustomEvents.back2menu);
  const UIEvent.dialogFinished({super.scene})
      : super(name: CustomEvents.dialogFinished);
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
