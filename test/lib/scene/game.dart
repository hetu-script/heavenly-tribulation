import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import 'package:samsara/components/fading_text.dart';

class GameScene extends Scene {
  GameScene({
    required super.id,
    required super.controller,
    required super.context,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    fitScreen();
  }

  @override
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    super.onTapUp(pointer, buttons, details);

    // final c = SpriteComponent2(spriteId: 'pepe.png', anchor: Anchor.center);
    // c.position = details.globalPosition.toVector2();
    // c.add(FadeEffect(target: c, controller: EffectController(duration: 1.0)));
    // add(c);

    final c2 = FadingText(
      'hit!\n100',
      movingUpOffset: 50,
      duration: 0.8,
      position: details.globalPosition.toVector2(),
      fadeOutAfterDuration: 0.3,
      textPaint: PresetTextPaints.danger.copyWith(
        (textStyle) => textStyle.copyWith(fontSize: 16),
      ),
    );
    add(c2);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.moveBy(-details.delta.toVector2() / camera.viewfinder.zoom);

    super.onDragUpdate(pointer, buttons, details);
  }
}
