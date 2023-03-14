import 'dart:async';

import 'package:flame/sprite.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/game_ui/progress_indicator.dart';

enum StatusTypes {
  block,
}

class Status extends GameComponent {
  @override
  String get id => super.id!;

  final String description;

  final String spriteId;
  Sprite? sprite;

  Status({
    required super.id,
    required this.description,
    required this.spriteId,
  });
}

class StatusBar extends GameComponent {
  String name;
  String? spriteId;
  late final Sprite sprite;

  late final DynamicColorProgressIndicator health;

  StatusBar({
    required this.name,
    this.spriteId,
  });

  @override
  FutureOr<void> onLoad() {
    health = DynamicColorProgressIndicator(
      position: Vector2(center.x, center.y - 160),
      size: Vector2(100, 10),
      value: 100,
      max: 100,
      colors: [Colors.red, Colors.green],
      showNumber: true,
    );
    add(health);
  }
}
