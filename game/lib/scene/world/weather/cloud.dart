import 'dart:math' as math;

import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';

const kCouldKindsCount = 12;

class AnimatedCloud extends GameComponent {
  Sprite? sprite;

  double _timeElasped = 0;
  double get timeElasped => _timeElasped;

  late final double duration;

  late final double velocity;

  final random = math.Random();

  AnimatedCloud({super.scale}) {
    velocity = 0.5 + random.nextDouble() * 2;
    duration = 20 + random.nextDouble() * 10;
    opacity = 0.4 + random.nextDouble() * 0.4;
    paint = Paint()..color = Colors.white.withOpacity(opacity);
  }

  @override
  Future<void> onLoad() async {
    final randomIndex = random.nextInt(kCouldKindsCount).toString();
    sprite = Sprite(await Flame.images.load('weather/cloud$randomIndex.png'));
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
