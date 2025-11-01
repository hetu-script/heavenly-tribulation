import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/game.dart';
import '../global.dart';

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
  String? background;
  bool loseOnEscape = false;

  void show(
    dynamic data, {
    // bool prebattlePreventClose = false,
    void Function()? onBattleStart,
    FutureOr<void> Function(bool, int)? onBattleEnd,
    String? background,
    bool loseOnEscape = false,
  }) {
    assert(data != null);
    showPrebattle = true;
    this.data = data;
    this.onBattleStart = onBattleStart;
    this.onBattleEnd = onBattleEnd;
    this.background = background;
    this.loseOnEscape = loseOnEscape;
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
    data = null;
    onBattleStart = null;
    onBattleEnd = null;
    background = null;
    loseOnEscape = false;
    notifyListeners();
  }
}

enum MerchantType {
  none,
  location,
  character,
  productionSite,
  depositBox,
}

class MerchantState with ChangeNotifier {
  bool showMerchant = false;
  bool materialMode = false;
  bool useShard = false;
  dynamic merchantData;
  dynamic priceFactor;
  dynamic filter;
  MerchantType merchantType = MerchantType.none;
  bool allowManualReplenish = false;

  void show(
    dynamic merchantData, {
    bool materialMode = false,
    bool useShard = false,
    dynamic priceFactor,
    dynamic filter,
    MerchantType merchantType = MerchantType.none,
    bool allowManualReplenish = false,
  }) {
    this.materialMode = materialMode;
    this.useShard = useShard;
    this.merchantData = merchantData;
    this.priceFactor = priceFactor;
    this.filter = filter;
    this.merchantType = merchantType;
    this.allowManualReplenish = allowManualReplenish;
    showMerchant = true;
    notifyListeners();
  }

  void close() {
    materialMode = false;
    useShard = false;
    merchantData = null;
    priceFactor = null;
    filter = null;
    merchantType = MerchantType.none;
    allowManualReplenish = false;
    showMerchant = false;
    notifyListeners();
  }
}
