import 'game_component.dart';
import '../gestures/gesture_mixin.dart';

abstract class GestureComponent extends GameComponent with HandlesGesture {
  GestureComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
  });
}
