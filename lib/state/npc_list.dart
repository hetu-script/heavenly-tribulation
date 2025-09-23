import 'package:flutter/foundation.dart';

class NpcListState with ChangeNotifier {
  Iterable<dynamic> npcs = [];

  void hide(String id) {
    npcs = npcs.where((npc) => npc['id'] != id);
    notifyListeners();
  }

  void update([Iterable? characters]) {
    npcs = characters ?? const [];
    notifyListeners();
  }
}
