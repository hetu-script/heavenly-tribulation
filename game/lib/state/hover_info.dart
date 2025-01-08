import 'dart:ui';

import 'package:flutter/foundation.dart';

class HoverInfoContentState extends ChangeNotifier {
  String? info;
  Rect? targetRect;

  void set(String? text, Rect? renderRect) {
    if (info != text || targetRect != renderRect) {
      info = text;
      targetRect = renderRect;
      notifyListeners();
    }
  }

  void hide() {
    info = null;
    targetRect = null;
    notifyListeners();
  }

  (dynamic, Rect?) get() {
    return (info, targetRect);
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
