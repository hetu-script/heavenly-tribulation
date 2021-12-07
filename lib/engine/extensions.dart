import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'scene/scene.dart';

extension Offset2Vector2 on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}

extension Vector2Ex on Vector2 {
  bool contains(Vector2 position) {
    return position.x > 0 && position.y > 0 && position.x < x && position.y < y;
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

abstract class GameComponent extends PositionComponent with HasGameRef<Scene> {
  bool _isVisible = true;

  @mustCallSuper
  set isVisible(bool value) => _isVisible = value;

  bool get isVisible {
    if (shouldRemove == true || size == Vector2.zero() || _isVisible == false) {
      return false;
    }
    return true;
  }

  bool isVisibleInCamera() {
    return gameRef.camera.isComponentOnCamera(this);
  }
}
