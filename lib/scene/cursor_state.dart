import 'package:flutter/material.dart';

import 'package:samsara/samsara.dart';

import '../ui.dart';

enum MouseCursorState {
  normal,
  click,
  drag,
}

mixin HasCursorState on Scene {
  set cursorState(MouseCursorState cursorState) {
    switch (cursorState) {
      case MouseCursorState.normal:
        mouseCursor = GameUI.cursor.resolve({});
      case MouseCursorState.click:
        mouseCursor = GameUI.cursor.resolve({WidgetState.hovered});
      case MouseCursorState.drag:
        mouseCursor = GameUI.cursor.resolve({WidgetState.dragged});
    }
  }
}
