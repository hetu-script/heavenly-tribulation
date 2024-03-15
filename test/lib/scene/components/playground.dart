import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
// import 'package:samsara/component/sprite_component.dart';
// import 'package:samsara/effect/fade_effect.dart';
// import 'package:flame/effects.dart';
import 'package:samsara/component/fading_text.dart';

class PlayGround extends GameComponent with HandlesGesture {
  PlayGround({
    required double width,
    required double height,
  }) : super(size: Vector2(width, height)) {
    onTapDown = (int buttons, Vector2 position) {
      // final c = SpriteComponent2(spriteId: 'pepe.png', anchor: Anchor.center);
      // c.position = details.globalPosition.toVector2();
      // c.add(FadeEffect(target: c, controller: EffectController(duration: 1.0)));
      // add(c);

      final c2 = FadingText(
        'hit!\n100',
        movingUpOffset: 50,
        duration: 0.8,
        position: position,
        fadeOutAfterDuration: 0.3,
        textPaint: PresetTextPaints.danger.copyWith(
          (textStyle) => textStyle.copyWith(fontSize: 16),
        ),
      );
      add(c2);
    };
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, PresetPaints.light);
  }
}
