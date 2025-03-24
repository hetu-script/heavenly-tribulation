import 'package:flutter/foundation.dart';

class NpcListState with ChangeNotifier {
  Iterable<dynamic> npcs = [];

  void update([Iterable<dynamic>? characters]) {
    if (characters != null) {
      npcs = characters;
    }
    notifyListeners();
  }
}
