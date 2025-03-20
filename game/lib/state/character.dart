import 'package:flutter/foundation.dart';

import '../game/data.dart';
import '../engine.dart';

class HeroState with ChangeNotifier {
  dynamic get heroData => GameData.heroData;

  void update() {
    GameData.heroData = engine.hetu.fetch('hero');
    notifyListeners();
  }
}

class EnemyState with ChangeNotifier {
  bool showPrebattle = false;
  dynamic enemyData;

  void update(dynamic data) {
    assert(data != null);
    enemyData = data;
    showPrebattle = true;
    notifyListeners();
  }

  void setPrebattleVisible([bool? value]) {
    if (value != null && showPrebattle != value) {
      showPrebattle = value;
      notifyListeners();
    } else if (showPrebattle != (enemyData != null)) {
      showPrebattle = enemyData != null;
      notifyListeners();
    }
  }

  void clear() {
    enemyData = null;
    showPrebattle = false;
    notifyListeners();
  }
}

class MerchantState with ChangeNotifier {
  bool showMerchant = false;
  dynamic merchantData;
  dynamic priceFactor;

  void show(dynamic merchantData, {dynamic priceFactor}) {
    this.merchantData = merchantData;
    this.priceFactor = priceFactor;
    showMerchant = true;
    notifyListeners();
  }

  void close() {
    merchantData = null;
    priceFactor = null;
    showMerchant = false;
    notifyListeners();
  }
}
