import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../engine.dart';
import '../../ui/shared/pointer_detector.dart';
import '../gestures/gesture_mixin.dart';

abstract class Scene extends FlameGame {
  static const overlayUIBuilderMapKey = 'overlayUI';

  final String key;

  Scene({required this.key});

  void end() {
    engine.leaveScene(key);
  }

  Vector2 get screenCenter => size / 2;

  Iterable<HandlesGesture> get _gestureComponents =>
      children.whereType<HandlesGesture>().cast<HandlesGesture>();

  void onTapDown(int pointer, int buttons, TapDownDetails details) {
    for (var c in _gestureComponents) {
      c.handleTapDown(pointer, buttons, details);
    }
  }

  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    for (var c in _gestureComponents) {
      c.handleTapUp(pointer, buttons, details);
    }
  }

  void onDragStart(int pointer, int buttons, DragStartDetails details) {
    for (var c in _gestureComponents) {
      c.handleDragStart(pointer, buttons, details);
    }
  }

  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    for (var c in _gestureComponents) {
      c.handleDragUpdate(pointer, buttons, details);
    }
  }

  void onDragEnd(int pointer, int buttons) {
    for (var c in _gestureComponents) {
      c.handleDragEnd(pointer, buttons);
    }
  }

  void onScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    for (var c in _gestureComponents) {
      c.handleScaleStart(touches, details);
    }
  }

  void onScaleUpdate(List<TouchDetails> touches, ScaleUpdateDetails details) {
    for (var c in _gestureComponents) {
      c.handleScaleUpdate(touches, details);
    }
  }

  void onScaleEnd() {
    for (var c in _gestureComponents) {
      c.handleScaleEnd();
    }
  }

  void onLongPress(int pointer, int buttons, LongPressStartDetails details) {
    for (var c in _gestureComponents) {
      c.handleLongPress(pointer, buttons, details);
    }
  }

  void onMouseMove(MouseMoveUpdateDetails details) {
    for (var c in _gestureComponents) {
      c.handleMouseMove(details);
    }
  }
}

class SceneController {
  Scene? _currentScene;
  Scene? get currentScene => _currentScene;

  final _cachedScenes = <String, Scene>{};

  final _sceneConstructors = <String, Function>{};

  void registerSceneConstructor<T extends Scene>(
      String name, T Function() constructor) {
    _sceneConstructors[name] = constructor;
  }

  @mustCallSuper
  Future<Scene> enterScene(String key) async {
    final _cached = _cachedScenes[key];
    if (_cached != null) {
      _currentScene = _cached;
      return _cached;
    } else {
      final constructor = _sceneConstructors[key]!;
      final Scene scene = await constructor();
      _cachedScenes[key] = scene;
      _currentScene = scene;
      return scene;
    }
  }

  void leaveScene(String key) {
    assert(_cachedScenes.containsKey(key));
    final scene = _cachedScenes[key]!;
    _cachedScenes.remove(key);
    if (_currentScene?.key == scene.key) {
      _currentScene = null;
    }
  }
}
