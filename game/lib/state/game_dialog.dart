import 'dart:collection';
// import 'dart:async';

import 'package:flutter/material.dart';

class ImageInfo {
  String imagePath;
  double positionXOffset, positionYOffset;

  ImageInfo(
    this.imagePath, {
    this.positionXOffset = 0.0,
    this.positionYOffset = 0.0,
  });
}

class GameDialogState with ChangeNotifier {
  bool isStarted = false;

  bool isFadeIn = false;
  bool isFadeOut = false;
  bool isImageFadeIn = false;
  bool isImageFadeOut = false;

  /// 图片的asset路径
  List<String> scenes = [];
  String? prevScene;

  /// key是图片的asset路径，value是图片x坐标的偏移值
  LinkedHashMap<String, ImageInfo> illustrations =
      LinkedHashMap<String, ImageInfo>();

  void start() {
    isStarted = true;
    notifyListeners();
  }

  void end() {
    isStarted = false;
    illustrations.clear();
    scenes.clear();
    notifyListeners();
  }

  void pushImage(String imageId,
      {double positionXOffset = 0.0,
      double positionYOffset = 0.0,
      bool fadeIn = false}) {
    isImageFadeIn = fadeIn;
    illustrations[imageId] = ImageInfo(
      'assets/images/illustration/$imageId.png',
      positionXOffset: positionXOffset,
      positionYOffset: positionYOffset,
    );
    notifyListeners();
  }

  void popImage({String? imageId, bool fadeOut = false}) {
    isImageFadeOut = fadeOut;
    if (imageId != null) {
      illustrations.remove(imageId);
    } else if (illustrations.isNotEmpty) {
      illustrations.remove(illustrations.keys.last);
    }
    notifyListeners();
  }

  void popAllImage() {
    illustrations.clear();
    notifyListeners();
  }

  void pushScene(String imageId, {bool fadeIn = false}) {
    isFadeIn = fadeIn;
    scenes.add('assets/images/cg/$imageId.png');
    notifyListeners();
  }

  void popScene({bool fadeOut = false}) {
    prevScene = scenes.last;
    isFadeOut = fadeOut;
    scenes.removeLast();
    notifyListeners();
  }

  void popAllScene() {
    scenes.clear();
    notifyListeners();
  }

  (String?, String?, bool, bool) get currentSceneInfo {
    return (scenes.lastOrNull, prevScene, isFadeIn, isFadeOut);
  }

  void clearFadeInfo() {
    isFadeIn = false;
    isFadeOut = false;
    isImageFadeIn = false;
    isImageFadeOut = false;
    prevScene = null;
  }
}
