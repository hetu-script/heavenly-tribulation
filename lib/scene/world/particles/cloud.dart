import 'dart:math' as math;

import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';

const kCloudPriority = 20000;
const kCouldKindCount = 12;

class ParticleCloud extends GameComponent {
  static final random = math.Random();

  Sprite? sprite;

  double _timeElasped = 0;
  double get timeElasped => _timeElasped;

  late final double duration;

  late final double velocity;

  ParticleCloud() : super(priority: kCloudPriority) {
    velocity = 0.5 + random.nextDouble() * 2;
    duration = 20 + random.nextDouble() * 10;
    opacity = 0.4 + random.nextDouble() * 0.4;
    // paint = Paint()..color = Colors.white.withAlpha((opacity * 255).round());
  }

  @override
  Future<void> onLoad() async {
    final randomIndex = random.nextInt(kCouldKindCount).toString();
    sprite = Sprite(
        await Flame.images.load('particles/clouds/cloud$randomIndex.png'));
  }

  @override
  void render(Canvas canvas) {
    sprite?.render(canvas, overridePaint: paint);
  }

  @override
  void update(double dt) {
    _timeElasped += dt;
    x -= dt * velocity;
    if (_timeElasped > duration) {
      removeFromParent();
    }
  }
}
