import 'dart:async';

import 'package:samsara/samsara.dart';
import 'package:samsara/component/fading_text.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import 'status/status.dart';
import '../common.dart';

const kDefaultAnimationStepTime = 0.7;

abstract class BattleState {
  static const stand = 'stand';
}

class BattleCharacter extends GameComponent {
  final Map<String, SpriteAnimationWithTicker> _animations = {};
  String _currentState = BattleState.stand;

  SpriteAnimationWithTicker get currentAnimation {
    assert(_animations.isNotEmpty);
    final anim = _animations[_currentState]!;
    return anim;
  }

  void setState(String state) {
    assert(_animations.containsKey('state'));
    _currentState = state;
  }

  final bool isHero;

  double life, lifeMax;

  bool get isDefeated => life <= 0;

  late final StatusBar status;

  BattleCharacter({
    super.id,
    super.position,
    super.size,
    super.anchor,
    required this.life,
    this.isHero = false,
  }) : lifeMax = life {
    assert(lifeMax > 0);
  }

  @override
  FutureOr<void> onLoad() async {
    final SpriteSheet charStandAnimSpriteList = SpriteSheet(
      image: await Flame.images.load('animation/hero/stand_sheet.png'),
      srcSize: kHeroSize,
    );
    final standAnimation = charStandAnimSpriteList.createAnimationWithTicker(
        row: 0, stepTime: kDefaultAnimationStepTime);
    _animations[BattleState.stand] = standAnimation;

    status = StatusBar(position: center);
    add(status);

    // if (!isHero) {
    //   flipHorizontally();
    //   x = kGamepadSize.x - x;

    //   status.flipHorizontally();
    // }
  }

  @override
  void render(Canvas canvas) {
    currentAnimation.currentSprite.renderRect(canvas, border);
  }

  @override
  void update(double dt) {
    currentAnimation.ticker.update(dt);
  }

  void attack({void Function()? onComplete}) {}

  void takeDamage(double damage) {
    assert(isLoaded);
    assert(damage >= 0);

    int d = damage.truncate();

    life -= damage;
    if (life < 0) {
      // d = (damage + life).truncate();
      life = 0;
    }

    final damageString = damage > 0 ? '-$d' : '$d';

    final c2 = FadingText(
      damageString,
      position: center,
      movingUpOffset: 50,
      duration: 0.8,
      fadeOutAfterDuration: 0.3,
      textPaint: DefaultTextPaint.danger.copyWith(
        (textStyle) => textStyle.copyWith(
          fontSize: 28,
        ),
      ),
    );
    game.add(c2);
  }
}
