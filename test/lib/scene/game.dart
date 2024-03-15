import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import 'components/playground.dart';
import '../global.dart';

class GameScene extends Scene {
  GameScene({
    required super.id,
    required super.controller,
    required super.context,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    camera.snapTo(size / 2);

    final p = PlayGround(width: 400.0, height: 320.0);
    world.add(p);

    engine.info('游戏界面可视区域大小：${p.size.x}x${p.size.y}');
    fitScreen(p.size);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.moveBy(-details.delta.toVector2() / camera.viewfinder.zoom);

    super.onDragUpdate(pointer, buttons, details);
  }
}
