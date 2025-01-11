import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';

import '../engine.dart';

class SceneControllerState with ChangeNotifier {
  Scene? scene;

  Future<void> push(String sceneId,
      {String? constructorId, dynamic arguments}) async {
    assert(scene?.id != sceneId);

    scene = await engine.pushScene(sceneId,
        constructorId: constructorId, arguments: arguments);

    notifyListeners();
  }

  Future<void> pop({bool clearCache = false}) async {
    scene = await engine.popScene(clearCache: clearCache);

    notifyListeners();
  }

  void switchTo(String sceneId, [dynamic arguments]) {
    scene = engine.switchScene(sceneId, arguments);

    notifyListeners();
  }

  Future<void> create(String sceneId,
      {String? constructorId, dynamic arguments}) async {
    scene = await engine.createScene(sceneId,
        constructorId: constructorId, arguments: arguments);

    notifyListeners();
  }

  void clearAll({String? except, dynamic arguments}) {
    engine.clearAllCachedScene(except: except);
    if (except != null) {
      scene = engine.switchScene(except, arguments);
    }

    notifyListeners();
  }
}
