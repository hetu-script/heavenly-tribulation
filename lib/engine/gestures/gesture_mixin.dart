import 'dart:async' show Timer;

import 'package:flutter/gestures.dart';
import 'package:flame/game.dart';

import '../extensions.dart';
import '../../ui/pointer_detector.dart' show TouchDetails;

export 'package:flutter/gestures.dart'
    show
        TapDownDetails,
        TapUpDetails,
        DragStartDetails,
        DragUpdateDetails,
        ScaleStartDetails,
        ScaleUpdateDetails,
        LongPressStartDetails;

mixin HandlesGesture on GameComponent {
  Camera get camera;

  bool enableGesture = true;
  int? tapPointer;
  bool isDragging = false, isScalling = false;

  /// A specific duration to detect double tap
  int doubleTapTimeConsider = 400;

  Timer? doubleTapTimer;

  void _cleanupTimer() {
    if (doubleTapTimer != null) {
      doubleTapTimer!.cancel();
    }
  }

  void onTap(int pointer) {}
  void onTapDown(int pointer, TapDownDetails details) {}
  void onTapUp(int pointer, TapUpDetails details) {}
  void onDoubleTap(int pointer, TapUpDetails details) {}
  void onTapCancel() {}
  void onDragStart(int pointer, DragStartDetails details) {}
  void onDragUpdate(int pointer, DragUpdateDetails details) {}
  void onDragEnd(int pointer) {}
  void onScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {}
  void onScaleUpdate(List<TouchDetails> touches, ScaleUpdateDetails details) {}
  void onScaleEnd() {}
  void onLongPress(LongPressStartDetails details) {}

  void handleTapDown(int pointer, TapDownDetails details) {
    if (!enableGesture || (tapPointer != null)) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      tapPointer = pointer;
      onTapDown(pointer, details);
    }
  }

  void handleTapUp(int pointer, TapUpDetails details) {
    if (!enableGesture || (tapPointer != pointer)) {
      tapPointer = null;
      return;
    }
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      if (doubleTapTimer == null) {
        doubleTapTimer =
            Timer(Duration(milliseconds: doubleTapTimeConsider), () {
          _cleanupTimer();
        });
      } else {
        _cleanupTimer();
        if (tapPointer == pointer) {
          onDoubleTap(pointer, details);
        } else {
          doubleTapTimer =
              Timer(Duration(milliseconds: doubleTapTimeConsider), () {
            _cleanupTimer();
          });
        }
      }
      onTapUp(pointer, details);
      onTap(pointer);
    } else {
      onTapCancel();
    }
    tapPointer = null;
  }

  void handleDragStart(int pointer, DragStartDetails details) {
    if (!enableGesture) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      isDragging = true;
      onDragStart(pointer, details);
    }
  }

  void handleDragUpdate(int pointer, DragUpdateDetails details) {
    if (!enableGesture || !isDragging) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      onDragUpdate(pointer, details);
    } else {
      handleDragEnd(pointer);
      if ((tapPointer != null) && (tapPointer == pointer)) {
        onTapCancel();
        tapPointer = null;
      }
    }
  }

  void handleDragEnd(int pointer) {
    if (!enableGesture) return;
    if (isDragging && (tapPointer == pointer)) {
      isDragging = false;
      onDragEnd(pointer);
    }
    tapPointer = null;
  }

  void handleScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    if (!enableGesture) return;
    assert(touches.length == 2);
    final pointerPosition1 = touches[0].currentLocalPosition.toVector2();
    final convertedPointerPosition1 = isHud
        ? pointerPosition1
        : gameRef.camera.screenToWorld(pointerPosition1);
    final pointerPosition2 = touches[1].currentLocalPosition.toVector2();
    final convertedPointerPosition2 = isHud
        ? pointerPosition2
        : gameRef.camera.screenToWorld(pointerPosition2);
    if (containsPoint(convertedPointerPosition1) &&
        containsPoint(convertedPointerPosition2)) {
      isScalling = true;
      onScaleStart(touches, details);
    } else {
      handleScaleEnd();
    }
  }

  void handleScaleUpdate(
      List<TouchDetails> touches, ScaleUpdateDetails details) {
    if (!enableGesture || !isScalling) return;
    assert(touches.length == 2);
    final pointerPosition1 = touches[0].currentLocalPosition.toVector2();
    final convertedPointerPosition1 = isHud
        ? pointerPosition1
        : gameRef.camera.screenToWorld(pointerPosition1);
    final pointerPosition2 = touches[1].currentLocalPosition.toVector2();
    final convertedPointerPosition2 = isHud
        ? pointerPosition2
        : gameRef.camera.screenToWorld(pointerPosition2);
    if (containsPoint(convertedPointerPosition1) &&
        containsPoint(convertedPointerPosition2)) {
      onScaleUpdate(touches, details);
    } else {
      handleScaleEnd();
    }
  }

  void handleScaleEnd() {
    if (!enableGesture) return;
    if (isScalling) {
      isScalling = false;
      onScaleEnd();
    }
    tapPointer = null;
  }

  void handleLongPress(int pointer, LongPressStartDetails details) {
    if (!enableGesture || tapPointer != pointer) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      onLongPress(details);
    }
  }
}
