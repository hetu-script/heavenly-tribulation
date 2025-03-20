import 'package:flutter/foundation.dart';

import '../game/data.dart';

class QuestState with ChangeNotifier {
  dynamic questsData;

  void update() {
    questsData =
        GameData.heroData?['quests']?[GameData.heroData?['activeQuestId']];
    notifyListeners();
  }
}
