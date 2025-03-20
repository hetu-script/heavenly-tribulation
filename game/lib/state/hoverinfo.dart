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

enum HoverType {
  general,
  player,
  npc,
  customer,
  merchant,
}

class HoverInfoContent {
  final dynamic data, data2;
  final HoverType type;
  final Rect rect;
  final double maxWidth;
  final HoverInfoDirection direction;
  final TextAlign textAlign;

  HoverInfoContent({
    required this.rect,
    required this.data,
    this.data2,
    this.type = HoverType.general,
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
    dynamic data2,
    // 如果isMerchant为false,data2可能是角色数据
    // 否则，data2可能是物品售价影响因子数据
    HoverType type = HoverType.general,
    double maxWidth = kHoverInfoMaxWidth,
    HoverInfoDirection direction = HoverInfoDirection.bottomCenter,
    TextAlign textAlign = TextAlign.center,
  }) {
    if (content?.rect == rect) {
      return;
    }

    content = HoverInfoContent(
      rect: rect,
      data: data,
      data2: data2,
      type: type,
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
