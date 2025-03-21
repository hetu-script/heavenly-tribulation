import 'package:flutter/foundation.dart';

class NewQuestsState with ChangeNotifier {
  dynamic quests;

  void update([List<dynamic>? quests]) {
    if (quests != null) {
      assert(quests.isNotEmpty);
    }
    this.quests = quests;
    notifyListeners();
  }
}

class NewItemsState with ChangeNotifier {
  dynamic items;

  void update([List<dynamic>? items]) {
    if (items != null) {
      assert(items.isNotEmpty);
    }
    this.items = items;
    notifyListeners();
  }
}
