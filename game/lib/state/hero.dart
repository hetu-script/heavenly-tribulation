import 'package:flutter/foundation.dart';

import '../config.dart';

class HeroState with ChangeNotifier {
  bool isShowHeroInfo = false;

  dynamic heroData;

  void showHeroInfo(bool value) {
    isShowHeroInfo = value;
    notifyListeners();
  }

  void update() {
    heroData = engine.hetu.fetch('hero');
    notifyListeners();
  }
}
