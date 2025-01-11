import 'dart:ui';

import 'package:flutter/foundation.dart';

enum HoverInfoDirection {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class HoverInfoContentState extends ChangeNotifier {
  bool isDetailed = false;
  dynamic data;
  Rect? targetRect;
  HoverInfoDirection direction = HoverInfoDirection.bottomCenter;

  void set(dynamic data, Rect? targetRect, {HoverInfoDirection? direction}) {
    if (this.data == data && this.targetRect == targetRect) return;

    this.data = data;
    this.targetRect = targetRect;
    if (direction != null) {
      this.direction = direction;
    }
    notifyListeners();
  }

  void switchDetailed() {
    isDetailed = !isDetailed;
    notifyListeners();
  }

  void hide() {
    data = null;
    targetRect = null;
    // isDetailed = false;
    notifyListeners();
  }

  (dynamic, Rect?, HoverInfoDirection) get() {
    return (data, targetRect, direction);
  }
}

class HoverInfoDeterminedRectState extends ChangeNotifier {
  Rect? rect;

  bool set(Rect renderBox) {
    if (rect == renderBox) return false;

    rect = renderBox;
    notifyListeners();

    return true;
  }
}
