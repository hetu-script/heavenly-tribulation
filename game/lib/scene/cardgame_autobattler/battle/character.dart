import 'dart:async';

import 'package:samsara/samsara.dart';
import 'package:samsara/component/fading_text.dart';

import 'status/status.dart';
import '../common.dart';

class BattleCharacter extends GameComponent {
  final SpriteAnimationWithTicker standAnimation;
  final SpriteAnimationWithTicker attackAnimation;

  final bool isHero;

  bool _isAttacking = false;

  bool get isAttacking => _isAttacking;

  double life, maxLife;

  bool get isDefeated => life <= 0;

  void Function(double life)? onTakeDamage;

  late final StatusBar status;

  BattleCharacter({
    super.id,
    super.position,
    super.size,
    required this.standAnimation,
    required this.attackAnimation,
    required this.life,
    super.anchor,
    this.isHero = false,
    this.onTakeDamage,
  }) : maxLife = life {
    assert(maxLife > 0);

    attackAnimation.ticker.onComplete = () {
      _isAttacking = false;
    };

    onTakeDamage = (life) {
      status.health.value = life;
    };
  }

  @override
  FutureOr<void> onLoad() {
    status = StatusBar(position: center);
    add(status);

    if (!isHero) {
      flipHorizontally();
      x = kGamepadSize.x - x;

      status.flipHorizontally();
    }
  }

  @override
  void render(Canvas canvas) {
    // canvas.drawRect(border, DefaultBorderPaint.danger);

    if (_isAttacking) {
      attackAnimation.currentSprite.renderRect(canvas, border);
    } else {
      standAnimation.currentSprite.renderRect(canvas, border);
    }
  }

  @override
  void update(double dt) {
    if (_isAttacking) {
      attackAnimation.ticker.update(dt);
    } else {
      standAnimation.ticker.update(dt);
    }
  }

  void attack({void Function()? onComplete}) {
    if (_isAttacking) {
      // TODO: 连续攻击？
      return;
    } else {
      attackAnimation.ticker.onComplete = onComplete;
      _isAttacking = true;
      attackAnimation.ticker.reset();
    }
  }

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

    onTakeDamage?.call(life);

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
