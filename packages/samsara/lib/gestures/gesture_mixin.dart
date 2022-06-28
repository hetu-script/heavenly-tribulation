import 'dart:async' show Timer;

import 'package:flutter/gestures.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart' show PositionType;

import '../extensions.dart';
import '../../ui/pointer_detector.dart'
    show TouchDetails, MouseMoveUpdateDetails;
import '../component/game_component.dart';

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

  void onTap(int pointer, int buttons, TapUpDetails details) {}
  void onTapDown(int pointer, int buttons, TapDownDetails details) {}
  void onTapUp(int pointer, int buttons, TapUpDetails details) {}
  void onDoubleTap(int pointer, int buttons, TapUpDetails details) {}
  void onTapCancel() {}
  void onDragStart(int pointer, int buttons, DragStartDetails details) {}
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {}
  void onDragEnd(int pointer, int buttons) {}
  void onScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {}
  void onScaleUpdate(List<TouchDetails> touches, ScaleUpdateDetails details) {}
  void onScaleEnd() {}
  void onLongPress(int buttons, LongPressStartDetails details) {}
  void onMouseMove(MouseMoveUpdateDetails details) {}

  void handleTapDown(int pointer, int buttons, TapDownDetails details) {
    if (!enableGesture || (tapPointer != null)) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      tapPointer = pointer;
      onTapDown(pointer, buttons, details);
    }
  }

  void handleTapUp(int pointer, int buttons, TapUpDetails details) {
    if (!enableGesture || (tapPointer != pointer)) {
      tapPointer = null;
      return;
    }
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      if (doubleTapTimer?.isActive ?? false) {
        doubleTapTimer?.cancel();
        if (tapPointer == pointer) {
          onDoubleTap(pointer, buttons, details);
        } else {
          doubleTapTimer =
              Timer(Duration(milliseconds: doubleTapTimeConsider), () {
            doubleTapTimer?.cancel();
          });
        }
      } else {
        onTap(pointer, buttons, details);
        doubleTapTimer =
            Timer(Duration(milliseconds: doubleTapTimeConsider), () {
          doubleTapTimer?.cancel();
        });
      }
      onTapUp(pointer, buttons, details);
    } else {
      onTapCancel();
    }
    tapPointer = null;
  }

  void handleDragStart(int pointer, int buttons, DragStartDetails details) {
    if (!enableGesture) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      isDragging = true;
      onDragStart(pointer, buttons, details);
    }
  }

  void handleDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    if (!enableGesture || !isDragging) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      onDragUpdate(pointer, buttons, details);
    } else {
      handleDragEnd(pointer, buttons);
      if ((tapPointer != null) && (tapPointer == pointer)) {
        onTapCancel();
        tapPointer = null;
      }
    }
  }

  void handleDragEnd(int pointer, int buttons) {
    if (!enableGesture) return;
    if (isDragging && (tapPointer == pointer)) {
      isDragging = false;
      onDragEnd(pointer, buttons);
    }
    tapPointer = null;
  }

  void handleScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    if (!enableGesture) return;
    assert(touches.length == 2);
    final pointerPosition1 = touches[0].currentLocalPosition.toVector2();
    final convertedPointerPosition1 = positionType != PositionType.game
        ? pointerPosition1
        : gameRef.camera.screenToWorld(pointerPosition1);
    final pointerPosition2 = touches[1].currentLocalPosition.toVector2();
    final convertedPointerPosition2 = positionType != PositionType.game
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
    final convertedPointerPosition1 = positionType != PositionType.game
        ? pointerPosition1
        : gameRef.camera.screenToWorld(pointerPosition1);
    final pointerPosition2 = touches[1].currentLocalPosition.toVector2();
    final convertedPointerPosition2 = positionType != PositionType.game
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

  void handleLongPress(
      int pointer, int buttons, LongPressStartDetails details) {
    if (!enableGesture || tapPointer != pointer) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      onLongPress(buttons, details);
    }
  }

  void handleMouseMove(MouseMoveUpdateDetails details) {
    if (!enableGesture) return;
    final pointerPosition = details.localPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      onMouseMove(details);
    }
  }
}
