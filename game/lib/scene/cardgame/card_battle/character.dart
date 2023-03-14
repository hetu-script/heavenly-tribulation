import 'dart:async';

import 'package:flame/sprite.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/component/fading_text.dart';

import '../common.dart';
import 'effect/status.dart';

class BattleCharacter extends GameComponent {
  final SpriteAnimation standAnimation;
  final SpriteAnimation attackAnimation;

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

    attackAnimation.onComplete = () {
      _isAttacking = false;
    };

    onTakeDamage = (life) {
      status.health.value = life;
    };
  }

  @override
  FutureOr<void> onLoad() {
    if (!isHero) {
      flipHorizontally();
      x = kGamepadSize.x - x;

      status.flipHorizontally();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.danger);

    if (_isAttacking) {
      attackAnimation.getSprite().renderRect(canvas, border);
    } else {
      standAnimation.getSprite().renderRect(canvas, border);
    }
  }

  @override
  void update(double dt) {
    if (_isAttacking) {
      attackAnimation.update(dt);
    } else {
      standAnimation.update(dt);
    }
  }

  void attack({void Function()? onComplete}) {
    if (_isAttacking) {
      // TODO: 连续攻击？
      return;
    } else {
      attackAnimation.onComplete = onComplete;
      _isAttacking = true;
      attackAnimation.reset();
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
