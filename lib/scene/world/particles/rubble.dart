import 'dart:math' as math;

import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';

const kRubblePriority = 20000;
const kRubbleKindCount = 14;
const kMinVelocity = 1;
const kMaxVelocity = 25;

const kMaxSpreadY = 100;

class ParticleRubble extends GameComponent {
  static final random = math.Random();

  Sprite? sprite;

  // 每秒钟移动的距离
  late final double velocity;

  ParticleRubble() : super(priority: kRubblePriority) {
    velocity = random.nextDouble() * kMaxVelocity + kMinVelocity;
    // paint = Paint()..color = Colors.white.withAlpha((opacity * 255).round());
  }

  @override
  Future<void> onLoad() async {
    x = random.nextDouble() * game.size.x;
    y = random.nextDouble() * kMaxSpreadY;

    final randomIndex = random.nextInt(kRubbleKindCount).toString();
    sprite = Sprite(
        await Flame.images.load('particles/rubbles/rubble$randomIndex.png'));
  }

  @override
  void render(Canvas canvas) {
    sprite?.render(canvas, position: position);
  }

  @override
  void update(double dt) {
    y += velocity;
    if (position.y > game.size.y) {
      removeFromParent();
    }
  }
}
