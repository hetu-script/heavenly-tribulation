import 'package:samsara/samsara.dart';
import 'state/game_dialog.dart';

abstract class Cursors {
  static const normal = 'normal';
  static const click = 'click';
  static const drag = 'drag';
  static const press = 'press';
}

final SamsaraEngine engine = SamsaraEngine();

final dialog = GameDialog.singleton;

const defaultGameSize = Size(1440.0, 810.0);
