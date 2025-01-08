import 'package:flutter/foundation.dart';

import '../scene/common.dart';
import '../scene/world/world.dart';
import '../engine.dart';
import '../data.dart';

class WorldMapSceneState with ChangeNotifier {
  WorldMapScene? scene;

  final List<String> _sceneIds = [];

  void clear() {
    for (final id in _sceneIds) {
      engine.clearCache(id);
    }
    _sceneIds.clear();
  }

  Future<String?> pop() async {
    // engine.clearCache(_sceneIds.last);
    _sceneIds.removeLast();
    String? currentSceneId;
    if (_sceneIds.isNotEmpty) {
      currentSceneId = _sceneIds.last;
      scene = await (engine.createScene<WorldMapScene>(
          contructorKey: kSceneLocationSite, sceneId: currentSceneId));
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
        contructorKey: kSceneTilemap,
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
