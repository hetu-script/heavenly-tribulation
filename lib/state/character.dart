import 'dart:async';

import 'package:flutter/foundation.dart';

import '../game/data.dart';
import '../engine.dart';

class HeroState with ChangeNotifier {
  dynamic get hero => GameData.hero;

  void update() {
    GameData.hero = engine.hetu.fetch('hero');
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
  // bool prebattlePreventClose = false;
  dynamic data;
  void Function()? onBattleStart;
  FutureOr<void> Function(bool, int)? onBattleEnd;

  void show(
    dynamic data, {
    // bool prebattlePreventClose = false,
    void Function()? onBattleStart,
    FutureOr<void> Function(bool, int)? onBattleEnd,
  }) {
    assert(data != null);
    showPrebattle = true;
    // prebattlePreventClose = prebattlePreventClose;
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
    showPrebattle = false;
    // prebattlePreventClose = false;
    data = null;
    onBattleStart = null;
    onBattleEnd = null;
    notifyListeners();
  }
}

enum MerchantType {
  location,
  character,
}

class MerchantState with ChangeNotifier {
  bool showMerchant = false;
  bool materialMode = false;
  bool useShard = false;
  dynamic data;
  dynamic priceFactor;
  dynamic filter;
  MerchantType type = MerchantType.location;

  (bool, bool, bool, dynamic, dynamic, dynamic, MerchantType) get() {
    return (
      showMerchant,
      materialMode,
      useShard,
      data,
      priceFactor,
      filter,
      type
    );
  }

  void show(
    dynamic data, {
    bool materialMode = false,
    bool useShard = false,
    dynamic priceFactor,
    dynamic filter,
    MerchantType type = MerchantType.location,
  }) {
    this.materialMode = materialMode;
    this.useShard = useShard;
    this.data = data;
    this.priceFactor = priceFactor;
    this.filter = filter;
    this.type = type;
    showMerchant = true;
    notifyListeners();
  }

  void close() {
    materialMode = false;
    useShard = false;
    data = null;
    priceFactor = null;
    filter = null;
    type = MerchantType.location;
    showMerchant = false;
    notifyListeners();
  }
}
