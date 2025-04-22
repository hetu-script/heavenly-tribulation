import 'package:flutter/foundation.dart';
import 'package:samsara/extensions.dart';

import '../game/data.dart';

class HeroAndGlobalHistoryState with ChangeNotifier {
  List<dynamic> incidents = [];

  void update({
    int limit = 20,
  }) {
    final String? heroId = GameData.hero?['id'];
    if (heroId == null) return;

    incidents.clear();
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

    notifyListeners();
  }
}
