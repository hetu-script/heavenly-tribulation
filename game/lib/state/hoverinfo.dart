import 'dart:ui';

import 'package:flutter/foundation.dart';

const kHoverInfoMaxWidth = 400.0;

enum HoverInfoDirection {
  topLeft,
  topCenter,
  topRight,
  leftTop,
  leftCenter,
  leftBottom,
  rightTop,
  rightCenter,
  rightBottom,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class HoverInfoContent {
  final dynamic data;
  final Rect rect;
  final double maxWidth;
  final HoverInfoDirection direction;
  final TextAlign textAlign;

  HoverInfoContent({
    required this.data,
    required this.rect,
    this.maxWidth = kHoverInfoMaxWidth,
    this.direction = HoverInfoDirection.bottomCenter,
    this.textAlign = TextAlign.center,
  });
}

class HoverInfoContentState extends ChangeNotifier {
  bool isDetailed = false;
  HoverInfoContent? content;

  void set(
    dynamic data,
    Rect rect, {
    double maxWidth = kHoverInfoMaxWidth,
    HoverInfoDirection direction = HoverInfoDirection.bottomCenter,
    TextAlign textAlign = TextAlign.center,
  }) {
    if (content?.rect == rect) {
      return;
    }

    content = HoverInfoContent(
      data: data,
      rect: rect,
      maxWidth: maxWidth,
      direction: direction,
      textAlign: textAlign,
    );
    notifyListeners();
  }

  void switchDetailed() {
    isDetailed = !isDetailed;
    notifyListeners();
  }

  void hide() {
    content = null;
    notifyListeners();
  }
}

class HoverInfoDeterminedRectState extends ChangeNotifier {
  Rect? rect;

  void set(Rect renderBox) {
    if (rect == renderBox) return;
    rect = renderBox;

    notifyListeners();
  }
}
