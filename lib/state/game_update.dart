import 'package:flutter/foundation.dart';

import '../logic/logic.dart';
import '../data/game.dart';
import '../engine.dart';
import 'package:samsara/extensions.dart';

class GameTimestampState with ChangeNotifier {
  String datetimeString = '';
  int timestamp = 0;

  void update({int? timestamp, String? datetimeString}) {
    if (timestamp != null && datetimeString != null) {
      this.timestamp = timestamp;
      this.datetimeString = datetimeString;
    } else {
      (timestamp, datetimeString) = GameLogic.calculateTimestamp();
      this.timestamp = timestamp;
      this.datetimeString = datetimeString;
    }
    notifyListeners();
  }

  (int, String) get() {
    return (timestamp, datetimeString);
  }
}

class HeroJournalUpdate with ChangeNotifier {
  List<dynamic> activeJournals = [];

  void update([List? journals]) {
    if (journals == null && GameData.hero != null) {
      journals = engine.hetu.invoke('getActiveJournals', namespace: 'Player');
    }
    activeJournals = journals ?? const [];
    notifyListeners();
  }
}

class HeroAndGlobalHistoryState with ChangeNotifier {
  List<dynamic> incidents = [];

  void update({
    int limit = 20,
  }) {
    final String? heroId = GameData.hero?['id'];
    if (heroId == null) return;

    incidents.clear();
    if (GameData.history != null) {
      for (final incident in (GameData.history.values as Iterable).reversed) {
        if (incident['subjectId'] == heroId ||
            incident['objectId'] == heroId ||
            incident['isGlobal']) {
          incidents.add(incident);
          if (limit > 0 && incidents.length >= limit) {
            break;
          }
        }
      }
      incidents = incidents.reversed.toList();
    }
    notifyListeners();
  }
}

class NpcListState with ChangeNotifier {
  Iterable<dynamic> npcs = [];

  void hide(String id) {
    npcs = npcs.where((npc) => npc['id'] != id);
    notifyListeners();
  }

  void update([Iterable characters = const []]) {
    npcs = characters;
    notifyListeners();
  }
}
