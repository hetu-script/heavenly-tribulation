import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class TouchDetails {
  int pointer;
  int buttons;
  Offset startLocalPosition;
  Offset startGlobalPosition;
  Offset currentLocalPosition;
  Offset currentGlobalPosition;

  TouchDetails(
    this.pointer,
    this.buttons,
    this.startGlobalPosition,
    this.startLocalPosition,
  )   : currentLocalPosition = startLocalPosition,
        currentGlobalPosition = startGlobalPosition;
}

class MouseMoveUpdateDetails {
  /// Creates details for a [MouseMoveUpdateDetails].
  ///
  /// The [delta] argument must not be null.
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  MouseMoveUpdateDetails({
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    required this.globalPosition,
    Offset? localPosition,
  })  : assert(
          primaryDelta == null ||
              (primaryDelta == delta.dx && delta.dy == 0.0) ||
              (primaryDelta == delta.dy && delta.dx == 0.0),
        ),
        localPosition = localPosition ?? globalPosition;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration? sourceTimeStamp;

  /// The amount the pointer has moved in the coordinate space of the event
  /// receiver since the previous update.
  ///
  /// Defaults to zero if not specified in the constructor.
  final Offset delta;

  /// The amount the pointer has moved along the primary axis in the coordinate
  /// space of the event receiver since the previous
  /// update.
  final double? primaryDelta;

  /// The pointer's global position when it triggered this update.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  final Offset globalPosition;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer contacted the screen.
  ///
  /// Defaults to [globalPosition] if not specified in the constructor.
  final Offset localPosition;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'DragUpdateDetails')}($delta)';
}

///  A widget that detects gestures.
/// * Supports Tap, Drag(start, update, end), Scale(start, update, end) and Long Press
/// * All callbacks be used simultaneously
///
/// For handle rotate event, please use rotateAngle on onScaleUpdate.
class PointerDetector extends StatefulWidget {
  /// Creates a widget that detects gestures.
  const PointerDetector({
    super.key,
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
    this.onMouseMove,
  });

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  final void Function(int pointer, int buttons, TapDownDetails details)?
      onTapDown;
  final void Function(int pointer, int buttons, TapUpDetails details)? onTapUp;

  /// A pointer has contacted the screen with a primary button and has begun to move.
  final void Function(int pointer, int buttons, DragStartDetails details)?
      onDragStart;

  /// A pointer that is in contact with the screen with a primary button and moving has moved again.
  final void Function(int pointer, int buttons, DragUpdateDetails details)?
      onDragUpdate;

  /// A pointer that was previously in contact with the screen with a primary
  /// button and moving is no longer in contact with the screen and was moving
  /// at a specific velocity when it stopped contacting the screen.
  final void Function(int pointer, int buttons)? onDragEnd;

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
  final void Function(int pointer, int buttons, LongPressStartDetails details)?
      onLongPress;

  /// A specific duration to detect long press
  final int longPressTickTimeConsider;

  final void Function(MouseMoveUpdateDetails details)? onMouseMove;

  @override
  _PointerDetectorState createState() => _PointerDetectorState();
}

enum _GestureState {
  pointerDown,
  dragStart,
  scaleStart,
  scalling,
  longPress,
  none,
}

class _PointerDetectorState extends State<PointerDetector> {
  final _touchDetails = <TouchDetails>[];
  double _initialScaleDistance = 0;
  _GestureState _gestureState = _GestureState.none;
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
    _touchDetails.add(TouchDetails(
        event.pointer, event.buttons, event.position, event.localPosition));

    if (touchCount == 1) {
      _gestureState = _GestureState.pointerDown;
      if (widget.onTapDown != null) {
        widget.onTapDown!(
            event.pointer,
            event.buttons,
            TapDownDetails(
                globalPosition: event.position,
                localPosition: event.localPosition,
                kind: event.kind));
      }
      startLongPressTimer(
          event.pointer,
          event.buttons,
          LongPressStartDetails(
              globalPosition: event.position,
              localPosition: event.localPosition));
    } else if (touchCount == 2) {
      _gestureState = _GestureState.scaleStart;
    } else {
      _gestureState = _GestureState.none;
    }
  }

  void initScaleAndRotate() {
    _initialScaleDistance = (_touchDetails[0].currentLocalPosition -
            _touchDetails[1].currentLocalPosition)
        .distance;
  }

  void onPointerMove(PointerMoveEvent event) {
    final detail =
        _touchDetails.firstWhere((detail) => detail.pointer == event.pointer);

    final distance = Offset(
            detail.currentLocalPosition.dx - event.localPosition.dx,
            detail.currentLocalPosition.dy - event.localPosition.dy)
        .distance;

    detail.currentLocalPosition = event.localPosition;
    detail.currentGlobalPosition = event.position;
    cleanupTimer();

    switch (_gestureState) {
      case _GestureState.none:
        if (event.kind == PointerDeviceKind.mouse) {
          if (widget.onMouseMove != null) {
            widget.onMouseMove!(MouseMoveUpdateDetails(
                delta: event.delta,
                sourceTimeStamp: event.timeStamp,
                globalPosition: event.position,
                localPosition: event.localPosition));
          }
        }
        break;
      case _GestureState.pointerDown:
        //print('move distance: ' + distance.toString());
        if (distance > 1) {
          _gestureState = _GestureState.dragStart;
          detail.startGlobalPosition = event.position;
          detail.startLocalPosition = event.localPosition;
          if (widget.onDragStart != null) {
            widget.onDragStart!(
                event.pointer,
                event.buttons,
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
              event.buttons,
              DragUpdateDetails(
                  sourceTimeStamp: event.timeStamp,
                  delta: event.delta,
                  globalPosition: event.position,
                  localPosition: event.localPosition));
        }
        break;
      case _GestureState.scaleStart:
        detail.startGlobalPosition = detail.currentGlobalPosition;
        detail.startLocalPosition = detail.currentLocalPosition;
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
              _angleBetweenLines(_touchDetails[0], _touchDetails[1]);
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
        detail.startGlobalPosition = detail.currentGlobalPosition;
        detail.startLocalPosition = detail.currentLocalPosition;
        break;
    }
  }

  double _angleBetweenLines(TouchDetails f, TouchDetails s) {
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
    // use the original detail's buttons information instead
    // because this information will be lost in the pointerUp event.
    final originalDetail =
        _touchDetails.singleWhere((detail) => detail.pointer == event.pointer);
    if (_gestureState == _GestureState.pointerDown) {
      widget.onTapUp?.call(
          event.pointer,
          originalDetail.buttons,
          TapUpDetails(
              globalPosition: event.position,
              localPosition: event.localPosition,
              kind: event.kind));
    } else if (_gestureState == _GestureState.scaleStart ||
        _gestureState == _GestureState.scalling) {
      _gestureState = _GestureState.none;
      widget.onScaleEnd?.call();
    } else if (_gestureState == _GestureState.dragStart) {
      _gestureState = _GestureState.none;
      widget.onDragEnd?.call(event.pointer, event.buttons);
    } else if (_gestureState == _GestureState.none && touchCount == 2) {
      _gestureState = _GestureState.scaleStart;
    } else {
      _gestureState = _GestureState.none;
    }

    _touchDetails.removeWhere((detail) => detail.pointer == event.pointer);
    // _lastTouchUpPos = event.localPosition;
  }

  void startLongPressTimer(
      int pointer, int buttons, LongPressStartDetails details) {
    if (widget.onLongPress != null) {
      if (_longPressTimer != null) {
        _longPressTimer!.cancel();
      }
      _longPressTimer =
          Timer(Duration(milliseconds: widget.longPressTickTimeConsider), () {
        if (touchCount == 1 && _touchDetails[0].pointer == pointer) {
          _gestureState = _GestureState.longPress;
          widget.onLongPress!(pointer, buttons, details);
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
