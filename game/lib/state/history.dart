import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';

import '../config.dart';

class HistoryState with ChangeNotifier {
  List<dynamic> incidents = [];

  void update({
    int count = 20,
    bool onlyHero = true,
  }) {
    final String? heroId = engine.hetu.invoke('getHeroId');
    if (heroId == null && onlyHero) return;

    final Iterable history =
        engine.hetu.fetch('currentWorldHistory')['incidents'].reversed;
    incidents.clear();
    final iter = history.iterator;
    var i = 0;
    while (iter.moveNext() && i < count) {
      final incident = iter.current;
      if ((incident['subjectIds'].contains(heroId) ||
              incident['objectIds'].contains(heroId)) ||
          incident['isGlobal']) {
        incidents.add(incident);
        ++i;
      }
    }
    incidents.reverse();
    notifyListeners();
  }
}
