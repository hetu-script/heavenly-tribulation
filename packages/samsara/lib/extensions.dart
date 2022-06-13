import 'dart:ui';

import 'package:flame/game.dart';
import 'component/game_component.dart';

extension Offset2Vector2 on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}

extension Vector2Ex on Vector2 {
  bool contains(Vector2 position) {
    return position.x > 0 && position.y > 0 && position.x < x && position.y < y;
  }

  Vector2 operator *(Vector2 other) {
    return Vector2(x * other.x, y * other.y);
  }
}

extension CameraExtension on Camera {
  Rect toRect() {
    return Rect.fromLTWH(position.x, position.y, gameSize.x, gameSize.y);
  }

  bool isComponentOnCamera(GameComponent c) {
    if (!c.isVisible) {
      return false;
    }
    return gameSize.contains(c.position);
  }
}
