import 'package:flame/sprite.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/component/fading_text.dart';

class FightSceneCharacter extends GameComponent {
  final String? id;

  final SpriteAnimation standAnimation;
  final SpriteAnimation attackAnimation;

  final bool isHero;

  bool _isAttacking = false;

  bool get isAttacking => _isAttacking;

  double life, maxLife;

  bool get isDefeated => life <= 0;

  void Function(double life)? onTakeDamage;

  FightSceneCharacter({
    this.id,
    double? x,
    double? y,
    required double width,
    required double height,
    required this.standAnimation,
    required this.attackAnimation,
    required this.life,
    super.anchor,
    this.isHero = false,
    this.onTakeDamage,
  })  : maxLife = life,
        super(position: Vector2(x ?? 0, y ?? 0), size: Vector2(width, height)) {
    assert(maxLife > 0);

    attackAnimation.onComplete = () {
      _isAttacking = false;
    };
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

  void takeDamage({double damage = 0}) {
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

  @override
  void render(Canvas canvas) {
    // canvas.drawRect(border, DefaultBorderPaint.danger);

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
}
