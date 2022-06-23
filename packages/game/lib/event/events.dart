import 'package:samsara/event.dart';

abstract class CustomEvents extends Events {
  static const back2menu = 'back2menu';
}

class MenuEvent extends GameEvent {
  const MenuEvent.back2menu({super.scene})
      : super(name: CustomEvents.back2menu);
}
