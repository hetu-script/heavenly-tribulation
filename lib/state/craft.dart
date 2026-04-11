import 'package:flutter/foundation.dart';

enum CraftMode {
  affix,
  scroll,
  all,
}

class CraftState with ChangeNotifier {
  bool isCrafting = false;
  int? rank;
  CraftMode craftMode = CraftMode.affix;

  void setCrafting(bool value,
      {int? rank, CraftMode craftMode = CraftMode.affix}) {
    isCrafting = value;
    this.rank = rank;
    this.craftMode = craftMode;
    notifyListeners();
  }
}
