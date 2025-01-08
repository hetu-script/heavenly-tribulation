import 'package:flutter/material.dart';

class WindowPriorityState with ChangeNotifier {
  final Set<String> visibleWindows = {};

  void toogle(String id) {
    if (visibleWindows.contains(id)) {
      visibleWindows.remove(id);
    } else {
      visibleWindows.add(id);
    }
    notifyListeners();
  }

  void clearAll() {
    visibleWindows.clear();
    notifyListeners();
  }

  void setUpFront(String id) {
    visibleWindows.remove(id);
    visibleWindows.add(id);
    notifyListeners();
  }

  void hide(String id) {
    visibleWindows.remove(id);
    notifyListeners();
  }
}

class WindowPositionState with ChangeNotifier {
  final Map<String, Offset> windowPositions = {};

  void updatePosition(String id, Offset offset) {
    windowPositions[id] = offset;
    notifyListeners();
  }
}
