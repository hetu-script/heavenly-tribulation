import 'dart:async';

import 'package:flutter/foundation.dart';

class NewQuestState with ChangeNotifier {
  dynamic quest;

  void update({dynamic quest}) {
    this.quest = quest;
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

  void update({int? rank}) {
    this.rank = rank;
    notifyListeners();
  }
}
