import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 卡牌碎裂动画的碎片粒子（消耗卡牌打出后碎裂消失用）
class _CardFragment extends PositionComponent {
  _CardFragment({
    required super.position,
    required this.velocity,
    required this.color,
    required super.size,
  }) : _paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

  static final _random = math.Random();

  final Vector2 velocity;
  final Color color;
  final Paint _paint;

  double _rotation = 0;
  final double _rotationSpeed = _random.nextDouble() * 12 - 6;
  double _lifetime = 0;

  static const _maxLifetime = 0.8;
  static const _gravity = 600.0;

  @override
  void update(double dt) {
    super.update(dt);

    _lifetime += dt;

    velocity.y += _gravity * dt;
    position += velocity * dt;
    _rotation += _rotationSpeed * dt;

    // 淡出
    if (_lifetime > _maxLifetime * 0.4) {
      final fadeProgress =
          (_lifetime - _maxLifetime * 0.4) / (_maxLifetime * 0.6);
      _paint.color =
          color.withAlpha(((1 - fadeProgress).clamp(0.0, 1.0) * 255).toInt());
    }

    if (_lifetime > _maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(width / 2, height / 2);
    canvas.rotate(_rotation);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      _paint,
    );
    canvas.restore();
  }
}

/// 卡牌碎裂效果：若干碎片从卡面位置向外飞出、旋转、下落并淡出
/// （参照 samsara-engine 的 ConfettiEffect 自绘粒子模式）
class CardShatterEffect extends PositionComponent {
  CardShatterEffect({
    required super.position,
    required super.size,
    super.priority,
  });

  static final _random = math.Random();

  static const _fragmentCount = 24;
  static const _colors = [
    Color(0xFFE7E7AC), // 卡框金
    Colors.white70,
    Colors.grey,
  ];

  @override
  void onMount() {
    super.onMount();
    for (var i = 0; i < _fragmentCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 150 + _random.nextDouble() * 300;
      add(_CardFragment(
        position: Vector2(
          _random.nextDouble() * size.x,
          _random.nextDouble() * size.y,
        ),
        velocity:
            Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 200),
        color: _colors[_random.nextInt(_colors.length)],
        size: Vector2.all(4 + _random.nextDouble() * 8),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (children.isEmpty) {
      removeFromParent();
    }
  }
}
