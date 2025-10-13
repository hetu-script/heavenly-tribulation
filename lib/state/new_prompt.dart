import 'dart:async';

import 'package:flutter/foundation.dart';

class JournalPromptState with ChangeNotifier {
  dynamic journal;
  Map<String, String>? selections;
  Completer? completer;

  void update(
      {dynamic journal,
      Map<String, String>? selections,
      Completer? completer}) {
    this.journal = journal;
    this.selections = selections;
    this.completer = completer;
    notifyListeners();
  }
}

class ItemsPromptState with ChangeNotifier {
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

class RankPromptState with ChangeNotifier {
  int? rank;
  Completer? completer;

  void update({int? rank, Completer? completer}) {
    this.rank = rank;
    this.completer = completer;
    notifyListeners();
  }
}
