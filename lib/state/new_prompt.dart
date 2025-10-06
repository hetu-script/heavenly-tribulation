import 'dart:async';

import 'package:flutter/foundation.dart';

class NewJournalState with ChangeNotifier {
  dynamic journal;
  Completer? completer;

  void update({dynamic journal, Completer? completer}) {
    this.journal = journal;
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
