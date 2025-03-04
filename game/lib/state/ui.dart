import 'package:flutter/foundation.dart';

class GameUIVisibilityState with ChangeNotifier {
  bool isVisible = false;

  void setVisible([bool? value]) {
    final newValue = value ?? false;
    if (isVisible != newValue) {
      isVisible = newValue;
      notifyListeners();
    }
  }
}
