import 'package:flutter/foundation.dart';

import '../config.dart';

class HeroState with ChangeNotifier {
  bool showHeroInfo = false;

  dynamic heroData;

  void update({bool showHeroInfo = true}) {
    this.showHeroInfo = showHeroInfo;
    heroData = engine.hetu.fetch('hero');
    notifyListeners();
  }
}
