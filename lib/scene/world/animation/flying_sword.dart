import 'package:flame/effects.dart';
import 'package:samsara/components/game_component.dart';
import 'package:samsara/animation/sprite_animation.dart';
import 'package:hetu_script/utils/math.dart' as math;

import '../../common.dart';

class FlyingSword extends GameComponent {
  late SpriteAnimationWithTicker _anim;
  Vector2 start, end;

  late Vector2 worldPosition;

  FlyingSword({
    required this.start,
    required this.end,
  }) : super(
          anchor: Anchor.center,
          priority: kWorldMapAnimationPriority,
        ) {
    _anim = SpriteAnimationWithTicker(
      animationId: 'flying_sword.png',
      loop: false,
      srcSize: Vector2(32, 48),
      stepTime: 0.2,
    );

    position = start;
    angle = math.radians(math.angle(start.x, start.y, end.x, end.y) - 90);
  }

  @override
  Future<void> onLoad() async {
    // TODO: implement onLoad
    super.onLoad();

    await _anim.load();

    size = _anim.currentSprite.srcSize;

    _anim.ticker.onComplete = () {
      add(MoveToEffect(end, EffectController(speed: 100), onComplete: () {
        removeFromParent();
      }));
    };
  }

  @override
  void update(double dt) {
    _anim.ticker.update(dt);
  }

  @override
  void render(Canvas canvas) {
    _anim.render(canvas);

    // canvas.drawRect(border, borderPaint);
  }
}
