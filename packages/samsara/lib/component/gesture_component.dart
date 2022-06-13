import 'package:flame/components.dart';

import 'game_component.dart';
import '../gestures/gesture_mixin.dart';

abstract class GestureComponent extends GameComponent with HandlesGesture {
  GestureComponent({
    Vector2? position,
    Vector2? size,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    int? priority,
  }) : super(
          position: position,
          size: size,
          scale: scale,
          angle: angle,
          anchor: anchor,
          priority: priority,
        );
}
