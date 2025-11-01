import 'dart:async';

import 'package:flutter/foundation.dart';

import '../global.dart';

class JournalPromptState with ChangeNotifier {
  dynamic journal;
  Map<String, String>? selections;
  Completer<String?>? completer;

  void update({
    dynamic journal,
    Map<String, String>? selectionsRaw,
    List<dynamic>? selections,
    List<dynamic>? interpolations,
    Completer<String?>? completer,
  }) {
    this.journal = journal;
    if (selectionsRaw != null) {
      this.selections = selectionsRaw;
    } else if (selections != null) {
      final Map<String, String> raw = {};
      for (final key in selections) {
        raw[key] = engine.locale(key, interpolations: interpolations);
      }
      this.selections = raw;
    } else {
      this.selections = null;
    }
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
