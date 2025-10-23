import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../data/common.dart';

export '../data/common.dart' show ItemType;

const kHoverInfoMaxWidth = 400.0;

enum HoverContentDirection {
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

class HoverContent {
  final dynamic data, data2;
  final ItemType type;
  final Rect rect;
  final double maxWidth;
  final HoverContentDirection direction;
  final TextAlign textAlign;

  HoverContent({
    required this.rect,
    required this.data,
    this.data2,
    this.type = ItemType.none,
    this.maxWidth = kHoverInfoMaxWidth,
    this.direction = HoverContentDirection.bottomCenter,
    this.textAlign = TextAlign.center,
  });
}

class HoverContentState extends ChangeNotifier {
  bool isDetailed = false;
  HoverContent? content;

  void show(
    dynamic data,
    Rect rect, {
    dynamic data2,
    // 如果isMerchant为false,data2可能是角色数据
    // 否则，data2可能是物品售价影响因子数据
    ItemType type = ItemType.none,
    double maxWidth = kHoverInfoMaxWidth,
    HoverContentDirection direction = HoverContentDirection.bottomCenter,
    TextAlign textAlign = TextAlign.center,
  }) {
    if (content?.rect == rect) {
      return;
    }

    content = HoverContent(
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

  void hide() async {
    if (content != null) {
      // 这里延迟一会儿
      // 因为 HoverInfo 窗口本身可能需要一小段时间才会渲染出来
      // 如果立刻清空有可能窗口本身之后重新显示导致清空不成功
      // Future.delayed(const Duration(milliseconds: 10), () {
      content = null;
      notifyListeners();
      // });
    }
  }
}

class HoverContentDeterminedRectState extends ChangeNotifier {
  Rect? rect;

  void set(Rect renderBox) {
    if (rect == renderBox) return;
    rect = renderBox;

    notifyListeners();
  }
}
