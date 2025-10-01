import 'dart:async';

import 'package:flutter/foundation.dart';

class NewQuestState with ChangeNotifier {
  dynamic quest;
  Completer? completer;

  void update({dynamic quest, Completer? completer}) {
    this.quest = quest;
    this.completer = completer;
    notifyListeners();
  }
}

class NewItemsState with ChangeNotifier {
  dynamic items;
  Completer? completer;

  void update({List<dynamic>? items, Completer? completer}) {
    if (items != null) {
      assert(items.isNotEmpty);
    }

    this.items = items;
    this.completer = completer;
    notifyListeners();
  }
}

class NewRankState with ChangeNotifier {
  int? rank;
  Completer? completer;

  void update({int? rank, Completer? completer}) {
    this.rank = rank;
    this.completer = completer;
    notifyListeners();
  }
}
