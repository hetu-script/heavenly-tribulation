import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../../engine/scene/scene.dart';
import '../shared/pointer_detector.dart';

class SceneWidget<T extends Scene> extends StatelessWidget {
  final T scene;

  const SceneWidget({Key? key, required this.scene}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PointerDetector(
      child: GameWidget(
        game: scene,
      ),
      onTapDown: scene.onTapDown,
      onTapUp: scene.onTapUp,
      onDragStart: scene.onDragStart,
      onDragUpdate: scene.onDragUpdate,
      onDragEnd: scene.onDragEnd,
      onScaleStart: scene.onScaleStart,
      onScaleUpdate: scene.onScaleUpdate,
      onScaleEnd: scene.onScaleEnd,
      onLongPress: scene.onLongPress,
      onMouseMove: scene.onMouseMove,
    );
  }
}
