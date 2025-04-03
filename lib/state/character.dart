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

class HeroPassivesDescriptionUpdate with ChangeNotifier {
  String description = '';

  void update(String newDescription) {
    description = newDescription;
    notifyListeners();
  }
}

class EnemyState with ChangeNotifier {
  bool showPrebattle = false;
  dynamic enemyData;

  void show(dynamic data) {
    assert(data != null);
    enemyData = data;
    showPrebattle = true;
    notifyListeners();
  }

  /// 设置战斗准备面板可见性
  /// 如果 value 为 null，则根据enemyData是否存在来决定
  void setPrebattleVisible([bool? value]) {
    value ??= enemyData != null;

    if (showPrebattle != value) {
      showPrebattle = value;
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

  void show(dynamic data, {dynamic priceFactor}) {
    merchantData = data;
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
