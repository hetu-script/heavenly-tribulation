import 'package:flutter/foundation.dart';

class CraftState with ChangeNotifier {
  bool isCrafting = false;
  int? rank;

  void setCrafting({int? rank}) {
    isCrafting = true;
    this.rank = rank;
    notifyListeners();
  }

  void clear() {
    isCrafting = false;
    rank = null;
    notifyListeners();
  }
}
