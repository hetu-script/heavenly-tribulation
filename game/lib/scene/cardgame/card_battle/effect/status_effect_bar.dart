import 'dart:async';

import 'package:flame/sprite.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/game_ui/progress_indicator.dart';

class StatusEffectBar extends GameComponent {
  String name;
  String? spriteId;
  late final Sprite sprite;

  late final DynamicColorProgressIndicator health;

  StatusEffectBar({
    required this.name,
    this.spriteId,
  });

  @override
  FutureOr<void> onLoad() {
    health = DynamicColorProgressIndicator(
      x: center.x,
      y: center.y - 160,
      width: 100,
      height: 10,
      value: 100,
      max: 100,
      colors: [Colors.red, Colors.green],
      showNumber: true,
    );
    add(health);
  }
}
