import 'package:flutter/foundation.dart';

class CraftState with ChangeNotifier {
  bool isCrafting = false;
  int? rank;

  void setCrafting(bool value, {int? rank}) {
    isCrafting = value;
    this.rank = rank;
    notifyListeners();
  }
}
