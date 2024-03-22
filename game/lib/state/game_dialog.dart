import 'dart:collection';

import 'package:flutter/material.dart';

class GameDialogState with ChangeNotifier {
  bool isStarted = false;

  /// 图片的asset路径
  List<String> scenes = [];

  /// key是图片的asset路径，value是图片x坐标的偏移值
  LinkedHashMap<String, double> illustrations = LinkedHashMap<String, double>();

  void start() {
    isStarted = true;
    notifyListeners();
  }

  void end() {
    isStarted = false;
    notifyListeners();
  }

  void pushImage(String image, {double positionXOffset = 0.0}) {
    assert(!illustrations.containsKey(image));
    illustrations[image] = positionXOffset;
    notifyListeners();
  }

  void popImage([String? image]) {
    if (image != null) {
      illustrations.remove(image);
    } else {
      illustrations.remove(illustrations.keys.last);
    }
    notifyListeners();
  }

  void popAllImage() {
    illustrations.clear();
    notifyListeners();
  }

  void pushScene(String image) {
    scenes.add(image);
    notifyListeners();
  }

  void popScene() {
    scenes.removeLast();
    notifyListeners();
  }

  void popAllScene() {
    scenes.clear();
    notifyListeners();
  }
}
