import 'package:meta/meta.dart';

import 'scene.dart';

class SceneController {
  Scene? _currentScene;
  Scene? get currentScene => _currentScene;

  final _cachedScenes = <String, Scene>{};

  final _sceneConstructors = <String, Future<Scene> Function([dynamic arg])>{};

  void registerSceneConstructor<T extends Scene>(
      String name, Future<T> Function([dynamic args]) constructor) {
    _sceneConstructors[name] = constructor;
  }

  @mustCallSuper
  Future<Scene> createScene(String key, String id, [dynamic args]) async {
    final _cached = _cachedScenes[id];
    if (_cached != null) {
      _currentScene = _cached;
      return _cached;
    } else {
      final constructor = _sceneConstructors[key]!;
      final Scene scene = await constructor(args);
      _cachedScenes[id] = scene;
      _currentScene = scene;
      return scene;
    }
  }

  void leaveScene(String id, {bool clearCache = false}) {
    assert(_cachedScenes.containsKey(id));
    if (_currentScene?.key == _cachedScenes[id]!.key) {
      _currentScene = null;
    }
    if (clearCache) {
      _cachedScenes.remove(id);
    }
  }

  /// 删除某个之前缓存的场景，这里允许接收一个不存在的id
  void clearCache(String id) {
    if (_cachedScenes.containsKey(id)) {
      if (_currentScene?.key == _cachedScenes[id]!.key) {
        _currentScene = null;
      }
      _cachedScenes.remove(id);
    }
  }
}
