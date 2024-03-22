import 'package:flutter/foundation.dart';

import '../scene/world/world.dart';
import '../config.dart';

class WorldMapSceneState with ChangeNotifier {
  WorldMapScene? scene;

  final List<String> _sceneIds = [];

  void clear() {
    for (final id in _sceneIds) {
      engine.leaveScene(id);
    }
    _sceneIds.clear();
  }

  Future<String?> popScene() async {
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

  Future<bool> pushScene({dynamic args}) async {
    bool isReload = true;
    final id = args['id'];
    scene = await engine.createScene(
      contructorKey: 'tilemap',
      sceneId: id,
      arg: args,
    ) as WorldMapScene;
    if (!engine.containsScene(id)) {
      _sceneIds.add(id);
      isReload = false;
    }
    notifyListeners();
    return isReload;
  }
}
