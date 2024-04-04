import 'package:flutter/foundation.dart';

class EditorToolState with ChangeNotifier {
  String? item;

  void reset() {
    item = null;
    notifyListeners();
  }

  void selectItem(String item) {
    this.item = item;
    notifyListeners();
  }
}
