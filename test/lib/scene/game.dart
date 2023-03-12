import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import 'components/playground.dart';

class GameScene extends Scene {
  GameScene({
    required super.id,
    required super.controller,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final p = PlayGround(width: 800.0, height: 640.0);

    add(p);

    fitScreen(Vector2(800.0, 640.0));
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.snapTo(camera.position - details.delta.toVector2());

    super.onDragUpdate(pointer, buttons, details);
  }
}
