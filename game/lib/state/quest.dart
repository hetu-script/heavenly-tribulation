import 'package:flutter/foundation.dart';

import '../engine.dart';

class QuestState with ChangeNotifier {
  Iterable<dynamic>? questsData = [];

  void update() {
    final hero = engine.hetu.fetch('hero');
    questsData = hero?['activeQuestIds']?.map((id) => hero?['quests']?[id]);
    notifyListeners();
  }
}
