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
  dynamic data;
  void Function()? onBattleStart;
  void Function(dynamic)? onBattleEnd;

  void show(
    dynamic data, {
    void Function()? onBattleStart,
    void Function(dynamic)? onBattleEnd,
  }) {
    assert(data != null);
    showPrebattle = true;
    this.data = data;
    this.onBattleStart = onBattleStart;
    this.onBattleEnd = onBattleEnd;
    notifyListeners();
  }

  /// 设置战斗准备面板可见性
  /// 如果 value 为 null，则根据enemyData是否存在来决定
  void setPrebattleVisible([bool? value]) {
    value ??= data != null;

    if (showPrebattle != value) {
      showPrebattle = value;
      notifyListeners();
    }
  }

  void clear() {
    data = null;
    showPrebattle = false;
    onBattleStart = null;
    onBattleEnd = null;
    notifyListeners();
  }
}

class MerchantState with ChangeNotifier {
  bool showMerchant = false;
  bool materialMode = false;
  bool useShard = false;
  dynamic data;
  dynamic priceFactor;
  dynamic filter;

  (bool, bool, bool, dynamic, dynamic, dynamic) get() {
    return (showMerchant, materialMode, useShard, data, priceFactor, filter);
  }

  void show(
    dynamic data, {
    bool materialMode = false,
    bool useShard = false,
    dynamic priceFactor,
    dynamic filter,
  }) {
    this.materialMode = materialMode;
    this.useShard = useShard;
    this.data = data;
    this.priceFactor = priceFactor;
    this.filter = filter;
    showMerchant = true;
    notifyListeners();
  }

  void close() {
    materialMode = false;
    useShard = false;
    data = null;
    priceFactor = null;
    filter = null;
    showMerchant = false;
    notifyListeners();
  }
}
