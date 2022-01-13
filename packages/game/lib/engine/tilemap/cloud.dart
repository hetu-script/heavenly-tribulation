import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';

import '../scene/scene.dart';

class TileMapCloud extends PositionComponent with HasGameRef<Scene> {
  late final Paint paint;

  Sprite? sprite;

  double _timeElasped = 0;
  double get timeElasped => _timeElasped;

  late final double duration;

  late final double velocity;

  bool visible = true;

  TileMapCloud({
    required Vector2 screenSize,
    Sprite? sprite,
    double? duration,
    double? opacity,
    double? velocity,
    Vector2? position,
    Vector2? scale,
  }) : super(position: position, scale: scale) {
    final random = math.Random();
    if (sprite != null) {
      sprite = sprite;
    } else {
      final randomIndex = random.nextInt(12).toString();
      Flame.images.load('weather/cloud$randomIndex.png').then((image) {
        this.sprite = Sprite(image);
      });
    }
    this.duration = duration ?? 16 + random.nextDouble() * 6;
    opacity ??= 0.3 + random.nextDouble() * 0.45;
    paint = Paint()..color = Colors.white.withOpacity(opacity);
    this.velocity = velocity ?? 0.2 + random.nextDouble() * 2;
    if (position != null) {
      this.position = position;
    } else {
      // 我也不知道为啥这里一定要除以 scale
      final randomPosX = (random.nextDouble() * screenSize.x) / 2;
      final randomPosY = (random.nextDouble() * screenSize.y) / 2;
      this.position = Vector2(randomPosX, randomPosY);
    }
  }

  @override
  void render(Canvas canvas) {
    if (visible) {
      sprite?.render(canvas, position: position, overridePaint: paint);
    }
  }

  @override
  void update(double dt) {
    _timeElasped += dt;
    x -= dt * velocity;
    if (_timeElasped > duration) {
      visible = false;
    }
  }
}
