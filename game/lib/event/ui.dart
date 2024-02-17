import 'package:samsara/event.dart';

abstract class UIEvents {
  static const back2menu = 'back_to_menu';
  static const needRebuildUI = 'need_rebuild_UI';
}

class UIEvent extends GameEvent {
  const UIEvent.back2menu({super.scene}) : super(name: UIEvents.back2menu);
  const UIEvent.needRebuildUI({super.scene})
      : super(name: UIEvents.needRebuildUI);
}
