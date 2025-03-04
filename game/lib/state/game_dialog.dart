// ignore_for_file: prefer_collection_literals

import 'dart:collection';
// import 'dart:async';

import 'package:flutter/material.dart';

class IllustrationInfo {
  final String path;
  final bool isFadeIn;
  final double offsetX, offsetY;

  const IllustrationInfo(
    this.path, {
    this.isFadeIn = false,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });
}

class SceneInfo {
  final String path;
  final bool isFadeIn;

  const SceneInfo(
    this.path, {
    this.isFadeIn = false,
  });
}

class GameDialogState with ChangeNotifier {
  bool isStarted = false;

  String? prevScene;

  /// key是图片的asset路径
  final scenes = LinkedHashSet<SceneInfo>();

  /// key是图片的asset路径，value是图片x坐标的偏移值
  final illustrations = LinkedHashSet<IllustrationInfo>();

  SceneInfo? get currentSceneInfo => scenes.lastOrNull;

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

  void pushImage(
    String imageId, {
    bool fadeIn = false,
    bool fadeOut = false,
    double offsetX = 0.0,
    double offsetY = 0.0,
  }) {
    assert(illustrations.any((c) => c.path == imageId) == false);

    illustrations.add(IllustrationInfo(
      'assets/images/illustration/$imageId',
      offsetX: offsetX,
      offsetY: offsetY,
      isFadeIn: fadeIn,
    ));
    notifyListeners();
  }

  void popImage({String? imageId}) {
    if (imageId != null) {
      illustrations.removeWhere((img) => img.path == imageId);
    } else if (illustrations.isNotEmpty) {
      illustrations.remove(illustrations.last);
    }
    notifyListeners();
  }

  void popAllImages() {
    illustrations.clear();
    notifyListeners();
  }

  void pushBackground(
    String imageId, {
    bool fadeIn = false,
  }) {
    assert(scenes.any((c) => c.path == imageId) == false);

    if (scenes.isNotEmpty) {
      prevScene = scenes.last.path;
    }

    scenes.add(SceneInfo('assets/images/cg/$imageId', isFadeIn: fadeIn));
    notifyListeners();
  }

  void popBackground() {
    if (scenes.isNotEmpty) {
      prevScene = scenes.last.path;
      scenes.remove(scenes.last);
      notifyListeners();
    }
  }

  void popAllBackgrounds() {
    scenes.clear();
    notifyListeners();
  }
}
