import 'package:flutter/foundation.dart';

class GameUIOverlayVisibilityState with ChangeNotifier {
  bool isVisible = false;

  void setVisible([bool value = true]) {
    isVisible = value;
    notifyListeners();
  }
}
