import 'package:meta/meta.dart';

import 'scene.dart';

class SceneController {
  Scene? _currentScene;
  Scene? get currentScene => _currentScene;

  final _cachedScenes = <String, Scene>{};

  final _sceneConstructors =
      <String, Future<Scene> Function([Map<String, dynamic>? arg])>{};

  void registerSceneConstructor<T extends Scene>(String name,
      Future<T> Function([Map<String, dynamic>? arg]) constructor) {
    _sceneConstructors[name] = constructor;
  }

  @mustCallSuper
  Future<Scene> createScene(String key, [Map<String, dynamic>? args]) async {
    final _cached = _cachedScenes[key];
    if (_cached != null) {
      _currentScene = _cached;
      return _cached;
    } else {
      final constructor = _sceneConstructors[key]!;
      final Scene scene = await constructor(args);
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
