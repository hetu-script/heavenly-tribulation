import 'package:flutter/foundation.dart';

class CraftState with ChangeNotifier {
  bool isCrafting = false;
  int? rank;
  bool scrollMode = false;

  void setCrafting({int? rank, bool scrollMode = false}) {
    isCrafting = true;
    this.rank = rank;
    this.scrollMode = scrollMode;
    notifyListeners();
  }

  void clear() {
    isCrafting = false;
    rank = null;
    scrollMode = false;
    notifyListeners();
  }
}
