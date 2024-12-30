import 'package:flutter/foundation.dart';

import '../scene/world/world.dart';
import '../engine.dart';
import '../data.dart';

class WorldMapSceneState with ChangeNotifier {
  WorldMapScene? scene;

  final List<String> _sceneIds = [];

  void clear() {
    for (final id in _sceneIds) {
      engine.leaveScene(id);
    }
    _sceneIds.clear();
  }

  Future<String?> pop() async {
    engine.leaveScene(_sceneIds.last);
    _sceneIds.removeLast();
    String? currentSceneId;
    if (_sceneIds.isNotEmpty) {
      currentSceneId = _sceneIds.last;
      scene = await (engine.createScene<WorldMapScene>(
          contructorKey: 'locationSite', sceneId: currentSceneId));
    } else {
      scene = null;
    }
    notifyListeners();
    return currentSceneId;
  }

  Future<WorldMapScene> push({dynamic args}) async {
    final id = args['id'];
    if (engine.containsScene(id)) {
      assert(_sceneIds.contains(id));
      scene = engine.switchScene(id)!;
    } else {
      scene = await engine.createScene(
        contructorKey: 'tilemap',
        sceneId: id,
        arg: args,
      ) as WorldMapScene;
      _sceneIds.add(id);
    }
    GameData.currentWorldId = scene!.id;
    notifyListeners();
    return scene!;
  }
}
