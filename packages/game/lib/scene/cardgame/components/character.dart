import 'package:flame/sprite.dart';
import 'package:samsara/samsara.dart';

class FightSceneCharacter extends GameComponent {
  final String? id;

  final SpriteAnimation standAnimation;
  final SpriteAnimation attackAnimation;

  bool _isAttacking = false;

  bool get isAttacking => _isAttacking;

  FightSceneCharacter({
    this.id,
    double? x,
    double? y,
    required this.standAnimation,
    required this.attackAnimation,
    super.anchor,
  }) : super(position: Vector2(x ?? 0, y ?? 0), size: Vector2(800, 640)) {
    attackAnimation.onComplete = () {
      _isAttacking = false;
    };
  }

  void attack() {
    if (_isAttacking) {
      // TODO: 连续攻击？
      return;
    } else {
      _isAttacking = true;
      attackAnimation.reset();
    }
  }

  @override
  void render(Canvas canvas) {
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
