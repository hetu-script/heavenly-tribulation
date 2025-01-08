import 'package:flutter/foundation.dart';

import '../engine.dart';

class GameOverlayVisibilityState with ChangeNotifier {
  bool isVisible = false;

  void show([bool value = true]) {
    isVisible = value;
    notifyListeners();
  }
}

class HeroState with ChangeNotifier {
  dynamic heroData;

  void update() {
    heroData = engine.hetu.fetch('hero');
    notifyListeners();
  }
}

class EnemyState with ChangeNotifier {
  bool showPrebattle = false;
  dynamic enemyData;

  void update(dynamic enemyData) {
    assert(enemyData != null);
    this.enemyData = enemyData;
    showPrebattle = true;
    notifyListeners();
  }

  void show(bool value) {
    showPrebattle = value;
  }

  void clear() {
    enemyData = null;
    showPrebattle = false;
    notifyListeners();
  }
}
