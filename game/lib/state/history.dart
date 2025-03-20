import 'package:flutter/foundation.dart';

import '../engine.dart';

class HeroAndGlobalHistoryState with ChangeNotifier {
  List<dynamic> incidents = [];

  void update({
    int limit = 20,
  }) {
    final String? heroId = engine.hetu.invoke('getHeroId');
    if (heroId == null) return;

    final List history = (engine.hetu.fetch('timeline') as List);
    incidents.clear();
    for (final incident in history.reversed) {
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

    notifyListeners();
  }
}
