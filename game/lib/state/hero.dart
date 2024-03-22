import 'package:flutter/foundation.dart';

import '../config.dart';

class HeroState with ChangeNotifier {
  dynamic heroData;

  void update() {
    heroData = engine.hetu.fetch('hero');
    notifyListeners();
  }
}
