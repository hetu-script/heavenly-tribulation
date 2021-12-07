import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:flame/game.dart';

import '../game.dart';
import '../event/event.dart';
import '../../ui/pointer_detector.dart';
import '../gestures/gesture_mixin.dart';

abstract class SceneEvents {
  static const started = 'scene_started';
  static const ended = 'scene_ended';
}

class SceneEvent extends Event {
  final String sceneKey;

  const SceneEvent({
    required String eventName,
    required this.sceneKey,
  }) : super(eventName);

  const SceneEvent.started({required String sceneKey})
      : this(eventName: SceneEvents.started, sceneKey: sceneKey);

  const SceneEvent.ended({required String sceneKey})
      : this(eventName: SceneEvents.ended, sceneKey: sceneKey);
}

class Scene extends FlameGame {
  final String key;

  final SamsaraGame game;

  Scene({
    required this.key,
    required this.game,
  });

  void end() {
    game.broadcast(SceneEvent.ended(sceneKey: key));
  }

  Vector2 get screenCenter => size / 2;

  Iterable<HandlesGesture> get _gestureComponents =>
      children.whereType<HandlesGesture>().cast<HandlesGesture>();

  void onTapDown(int pointer, TapDownDetails details) {
    for (var c in _gestureComponents) {
      c.handleTapDown(pointer, details);
    }
  }

  void onTapUp(int pointer, TapUpDetails details) {
    for (var c in _gestureComponents) {
      c.handleTapUp(pointer, details);
    }
  }

  void onDragStart(int pointer, DragStartDetails details) {
    for (var c in _gestureComponents) {
      c.handleDragStart(pointer, details);
    }
  }

  void onDragUpdate(int pointer, DragUpdateDetails details) {
    for (var c in _gestureComponents) {
      c.handleDragUpdate(pointer, details);
    }
  }

  void onDragEnd(int pointer) {
    for (var c in _gestureComponents) {
      c.handleDragEnd(pointer);
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

  void onLongPress(int pointer, LongPressStartDetails details) {
    for (var c in _gestureComponents) {
      c.handleLongPress(pointer, details);
    }
  }

  Widget get widget {
    return PointerDetector(
      child: GameWidget(
        game: this,
        // overlayBuilderMap: {
        //   'BattleGameTeamBuilder': (BuildContext ctx, Scene scene) {
        //     return const Text('A pause menu');
        //   }
        // },
      ),
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      onLongPress: onLongPress,
    );
  }
}

class SceneController {
  static var _instanceIndex = 0;

  Scene? get currentScene =>
      _cachedScenes.isNotEmpty ? _cachedScenes.values.last : null;

  String? get currentSceneName {
    if (_cachedScenes.isNotEmpty) {
      return _cachedScenes.keys.last;
    } else {
      return null;
    }
  }

  final LinkedHashMap<String, Scene> _cachedScenes =
      LinkedHashMap<String, Scene>();

  final _sceneConstructors = <String, Function>{};

  void registerSceneConstructor<T extends Scene>(
      String name, T Function() constructor) {
    _sceneConstructors[name] = constructor;
  }

  @mustCallSuper
  Future<Scene> createScene(String name) async {
    final constructor = _sceneConstructors[name]!;
    final Scene scene = await constructor();
    _cachedScenes['$name${_instanceIndex++}'] = scene;
    return scene;
  }

  Future<void> switchScene(String name) async {
    final _cached = _cachedScenes[name];
    if (_cached != null) {
      _cachedScenes.remove(name);
      _cachedScenes.addAll({name: _cached});
    }
  }

  void leaveScene() {
    if (_cachedScenes.isNotEmpty) {
      _cachedScenes.remove(_cachedScenes.keys.last);
    }
  }
}
