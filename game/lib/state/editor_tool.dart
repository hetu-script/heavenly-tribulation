import 'package:flutter/foundation.dart';

class EditorToolState with ChangeNotifier {
  String? selectedId;

  void reset() {
    selectedId = null;
    notifyListeners();
  }

  void selectItem(String item) {
    selectedId = item;
    notifyListeners();
  }
}
