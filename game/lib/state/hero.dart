import 'package:flutter/foundation.dart';

import '../engine.dart';

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

  void setPrebattleVisible([bool? value]) {
    if (value != null) {
      showPrebattle = value;
    } else {
      showPrebattle = enemyData != null;
    }
    notifyListeners();
  }

  void clear() {
    enemyData = null;
    notifyListeners();
  }
}
