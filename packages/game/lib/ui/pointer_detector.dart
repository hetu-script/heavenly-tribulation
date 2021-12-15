import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';

///  A widget that detects gestures.
/// * Supports Tap, Drag(start, update, end), Scale(start, update, end) and Long Press
/// * All callbacks be used simultaneously
///
/// For handle rotate event, please use rotateAngle on onScaleUpdate.
class PointerDetector extends StatefulWidget {
  /// Creates a widget that detects gestures.
  const PointerDetector({
    Key? key,
    required this.child,
    this.onTapDown,
    this.onTapUp,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onLongPress,
    this.longPressTickTimeConsider = 400,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  final void Function(int pointer, TapDownDetails details)? onTapDown;
  final void Function(int pointer, TapUpDetails details)? onTapUp;

  /// A pointer has contacted the screen with a primary button and has begun to move.
  final void Function(int pointer, DragStartDetails details)? onDragStart;

  /// A pointer that is in contact with the screen with a primary button and moving has moved again.
  final void Function(int pointer, DragUpdateDetails details)? onDragUpdate;

  /// A pointer that was previously in contact with the screen with a primary
  /// button and moving is no longer in contact with the screen and was moving
  /// at a specific velocity when it stopped contacting the screen.
  final void Function(int pointer)? onDragEnd;

  /// The pointers in contact with the screen have established a focal point and
  /// initial scale of 1.0.
  final void Function(List<TouchDetails> touches, ScaleStartDetails details)?
      onScaleStart;

  /// The pointers in contact with the screen have indicated a new focal point
  /// and/or scale.
  ///
  /// =============================================
  ///
  /// **changedFocusPoint** the current focus point
  ///
  /// **scale** the scale value
  ///
  /// **rotationAngle** the rotate angle in radians - using for rotate
  final void Function(List<TouchDetails> touches, ScaleUpdateDetails details)?
      onScaleUpdate;

  /// The pointers are no longer in contact with the screen.
  final void Function()? onScaleEnd;

  /// A pointer has remained in contact with the screen at the same location for a long period of time
  ///
  /// @param
  final void Function(int pointer, LongPressStartDetails details)? onLongPress;

  /// A specific duration to detect long press
  final int longPressTickTimeConsider;

  @override
  _PointerDetectorState createState() => _PointerDetectorState();
}

enum _GestureState {
  pointerDown,
  dragStart,
  scaleStart,
  scalling,
  longPress,
  unknown
}

class _PointerDetectorState extends State<PointerDetector> {
  final _touchDetails = <TouchDetails>[];
  double _initialScaleDistance = 0;
  _GestureState _gestureState = _GestureState.unknown;
  Timer? _longPressTimer;
  // var _lastTouchUpPos = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    return Listener(
      child: widget.child,
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerMove: onPointerMove,
      onPointerCancel: onPointerUp,
    );
  }

  void onPointerDown(PointerDownEvent event) {
    _touchDetails
        .add(TouchDetails(event.pointer, event.position, event.localPosition));

    if (touchCount == 1) {
      _gestureState = _GestureState.pointerDown;
      if (widget.onTapDown != null) {
        widget.onTapDown!(
            event.pointer,
            TapDownDetails(
                globalPosition: event.position,
                localPosition: event.localPosition,
                kind: event.kind));
      }
      startLongPressTimer(
          event.pointer,
          LongPressStartDetails(
              globalPosition: event.position,
              localPosition: event.localPosition));
    } else if (touchCount == 2) {
      _gestureState = _GestureState.scaleStart;
    } else {
      _gestureState = _GestureState.unknown;
    }
  }

  void initScaleAndRotate() {
    _initialScaleDistance = (_touchDetails[0].currentLocalPosition -
            _touchDetails[1].currentLocalPosition)
        .distance;
  }

  void onPointerMove(PointerMoveEvent event) {
    final touch =
        _touchDetails.firstWhere((touch) => touch.pointer == event.pointer);

    final distance = Offset(
            touch.currentLocalPosition.dx - event.localPosition.dx,
            touch.currentLocalPosition.dy - event.localPosition.dy)
        .distance;

    touch.currentLocalPosition = event.localPosition;
    touch.currentGlobalPosition = event.position;
    cleanupTimer();

    switch (_gestureState) {
      case _GestureState.pointerDown:
        //print('move distance: ' + distance.toString());
        if (distance > 1) {
          _gestureState = _GestureState.dragStart;
          touch.startGlobalPosition = event.position;
          touch.startLocalPosition = event.localPosition;
          if (widget.onDragStart != null) {
            widget.onDragStart!(
                event.pointer,
                DragStartDetails(
                    sourceTimeStamp: event.timeStamp,
                    globalPosition: event.position,
                    localPosition: event.localPosition));
          }
        }
        break;
      case _GestureState.dragStart:
        if (widget.onDragUpdate != null) {
          widget.onDragUpdate!(
              event.pointer,
              DragUpdateDetails(
                  sourceTimeStamp: event.timeStamp,
                  delta: event.delta,
                  globalPosition: event.position,
                  localPosition: event.localPosition));
        }
        break;
      case _GestureState.scaleStart:
        touch.startGlobalPosition = touch.currentGlobalPosition;
        touch.startLocalPosition = touch.currentLocalPosition;
        _gestureState = _GestureState.scalling;
        initScaleAndRotate();
        if (widget.onScaleStart != null) {
          final centerGlobal = (_touchDetails[0].currentGlobalPosition +
                  _touchDetails[1].currentGlobalPosition) /
              2;
          final centerLocal = (_touchDetails[0].currentLocalPosition +
                  _touchDetails[1].currentLocalPosition) /
              2;
          widget.onScaleStart!(
              _touchDetails,
              ScaleStartDetails(
                  focalPoint: centerGlobal, localFocalPoint: centerLocal));
        }
        break;
      case _GestureState.scalling:
        if (widget.onScaleUpdate != null) {
          final rotation =
              angleBetweenLines(_touchDetails[0], _touchDetails[1]);
          final newDistance = (_touchDetails[0].currentLocalPosition -
                  _touchDetails[1].currentLocalPosition)
              .distance;
          final centerGlobal = (_touchDetails[0].currentGlobalPosition +
                  _touchDetails[1].currentGlobalPosition) /
              2;
          final centerLocal = (_touchDetails[0].currentLocalPosition +
                  _touchDetails[1].currentLocalPosition) /
              2;
          widget.onScaleUpdate!(
              _touchDetails,
              ScaleUpdateDetails(
                  focalPoint: centerGlobal,
                  localFocalPoint: centerLocal,
                  scale: newDistance / _initialScaleDistance,
                  rotation: rotation));
        }
        break;
      default:
        touch.startGlobalPosition = touch.currentGlobalPosition;
        touch.startLocalPosition = touch.currentLocalPosition;
        break;
    }
  }

  double angleBetweenLines(TouchDetails f, TouchDetails s) {
    double angle1 = math.atan2(
        f.currentLocalPosition.dy - s.currentLocalPosition.dy,
        f.currentLocalPosition.dx - s.currentLocalPosition.dx);
    double angle2 = math.atan2(
        f.currentLocalPosition.dy - s.currentLocalPosition.dy,
        f.currentLocalPosition.dx - s.currentLocalPosition.dx);

    double angle = degrees(angle1 - angle2) % 360;
    if (angle < -180.0) angle += 360.0;
    if (angle > 180.0) angle -= 360.0;
    return radians(angle);
  }

  void onPointerUp(PointerEvent event) {
    _touchDetails.removeWhere((touch) => touch.pointer == event.pointer);

    if (_gestureState == _GestureState.pointerDown) {
      widget.onTapUp?.call(
          event.pointer,
          TapUpDetails(
              globalPosition: event.position,
              localPosition: event.localPosition,
              kind: event.kind));
    } else if (_gestureState == _GestureState.scaleStart ||
        _gestureState == _GestureState.scalling) {
      _gestureState = _GestureState.unknown;
      widget.onScaleEnd?.call();
    } else if (_gestureState == _GestureState.dragStart) {
      _gestureState = _GestureState.unknown;
      widget.onDragEnd?.call(event.pointer);
    } else if (_gestureState == _GestureState.unknown && touchCount == 2) {
      _gestureState = _GestureState.scaleStart;
    } else {
      _gestureState = _GestureState.unknown;
    }

    // _lastTouchUpPos = event.localPosition;
  }

  void startLongPressTimer(int pointer, LongPressStartDetails details) {
    if (widget.onLongPress != null) {
      if (_longPressTimer != null) {
        _longPressTimer!.cancel();
      }
      _longPressTimer =
          Timer(Duration(milliseconds: widget.longPressTickTimeConsider), () {
        if (touchCount == 1 && _touchDetails[0].pointer == pointer) {
          _gestureState = _GestureState.longPress;
          widget.onLongPress!(pointer, details);
        }
      });
    }
  }

  void cleanupTimer() {
    if (_longPressTimer != null) {
      _longPressTimer!.cancel();
    }
  }

  get touchCount => _touchDetails.length;

  /// Constant factor to convert and angle from degrees to radians.
  final double degrees2Radians = math.pi / 180.0;

  /// Constant factor to convert and angle from radians to degrees.
  final double radians2Degrees = 180.0 / math.pi;

  double degrees(double radians) => radians * radians2Degrees;

  /// Convert [degrees] to radians.
  double radians(double degrees) => degrees * degrees2Radians;
}

class TouchDetails {
  int pointer;
  Offset startLocalPosition;
  Offset startGlobalPosition;
  Offset currentLocalPosition;
  Offset currentGlobalPosition;

  TouchDetails(this.pointer, this.startGlobalPosition, this.startLocalPosition)
      : currentLocalPosition = startLocalPosition,
        currentGlobalPosition = startGlobalPosition;
}
