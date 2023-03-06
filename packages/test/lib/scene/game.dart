import 'package:samsara/samsara.dart';
import 'package:samsara/utils/uid.dart';

import 'components/playground.dart';

class GameScene extends Scene {
  GameScene({
    required super.controller,
  }) : super(name: 'game', key: 'game${uid(4)}');

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final p = PlayGround(width: 800.0, height: 640.0);

    add(p);
  }

  // @override
  // void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
  //   camera.snapTo(camera.position - details.delta.toVector2());

  //   super.onDragUpdate(pointer, buttons, details);
  // }
}
