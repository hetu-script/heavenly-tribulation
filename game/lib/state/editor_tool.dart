import 'package:flutter/foundation.dart';

enum EditorToolItems {
  sea,
  plain,
  forest,
  mountain,
  city,
  shelf,
  farmfield,
  // pond,
  fishZone,
  stormZone,
  delete,
  none,
}

EditorToolItems getEditorToolItem(String? id) {
  return EditorToolItems.values.firstWhere((element) => element.name == id,
      orElse: () => EditorToolItems.none);
}

class EditorToolState with ChangeNotifier {
  EditorToolItems item = EditorToolItems.none;

  void reset() {
    item = EditorToolItems.none;
    notifyListeners();
  }

  void selectItem(EditorToolItems item) {
    this.item = item;
    notifyListeners();
  }
}
