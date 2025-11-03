import 'package:samsara/samsara.dart';

import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import '../ui.dart';

enum MouseCursorState {
  normal,
  click,
  drag,
  press,
  talk,
  sandglass,
}

mixin HasCursorState on Scene {
  set cursorState(MouseCursorState cursorState) {
    switch (cursorState) {
      case MouseCursorState.normal:
        mouseCursor = FlutterCustomMemoryImageCursor(key: Cursors.normal);
      case MouseCursorState.click:
        mouseCursor = FlutterCustomMemoryImageCursor(key: Cursors.click);
      case MouseCursorState.drag:
        mouseCursor = FlutterCustomMemoryImageCursor(key: Cursors.drag);
      case MouseCursorState.press:
        mouseCursor = FlutterCustomMemoryImageCursor(key: Cursors.press);
      case MouseCursorState.talk:
        mouseCursor = FlutterCustomMemoryImageCursor(key: Cursors.talk);
      case MouseCursorState.sandglass:
        mouseCursor = FlutterCustomMemoryImageCursor(key: Cursors.sandglass);
    }
  }
}
