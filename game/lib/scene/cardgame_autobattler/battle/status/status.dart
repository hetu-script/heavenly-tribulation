import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/game/progress_indicator.dart';

class StatusEffect extends GameComponent {
  @override
  String get id => super.id!;

  final String title, description;

  final String spriteId;
  Sprite? sprite;

  int count;

  StatusEffect({
    required super.id,
    required this.title,
    required this.description,
    required this.spriteId,
    required this.count,
    super.position,
    Vector2? size,
  }) : super(size: size ?? Vector2(20, 20));

  @override
  FutureOr<void> onLoad() async {
    sprite = Sprite(await Flame.images.load('$spriteId.png'));
  }

  @override
  void render(Canvas canvas) {
    sprite?.renderRect(canvas, border);
  }

  static final Map<String, StatusEffect Function(int count)> _constructors = {};

  static registerEffect(
      String id, StatusEffect Function(int count) constructor) {
    _constructors[id] = constructor;
  }

  factory StatusEffect.create(String id, int count) {
    assert(_constructors.containsKey(id));
    assert(count > 0);
    final ctor = _constructors[id]!;
    final effect = ctor.call(count);
    assert(effect.id == id);
    return effect;
  }
}

class StatusBar extends GameComponent {
  static const healthBarHeight = 10.0;

  late final DynamicColorProgressIndicator health;

  double life, maxLife;

  final Map<String, StatusEffect> effects = {};

  StatusBar({
    super.position,
    Vector2? size,
    this.life = 100,
    this.maxLife = 100,
  }) : super(
          anchor: Anchor.center,
          size: size ?? Vector2(100, 30),
        );

  @override
  set height(double value) {
    super.height = value;

    health.y = height - healthBarHeight;
  }

  void addEffect(String id, int count) {
    if (effects.containsKey(id)) {
      final effect = effects[id]!;
      effect.count += count;
    } else {
      final effect = StatusEffect.create(id, count);
      add(effect);
      effects[id] = effect;
    }
  }

  @override
  FutureOr<void> onLoad() {
    health = DynamicColorProgressIndicator(
      position: Vector2(0, height - healthBarHeight),
      size: Vector2(width, healthBarHeight),
      value: life,
      max: maxLife,
      colors: [Colors.red, Colors.green],
      showNumber: true,
    );
    add(health);
  }

  @override
  void render(Canvas canvas) {
    // canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
