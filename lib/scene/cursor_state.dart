import 'package:samsara/samsara.dart';

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
  MouseCursorState? _currentCursorState;

  /// 切换当前场景的鼠标光标。
  ///
  /// 这里赋值的 [GameCursor] 与普通的 MouseCursor 不同：
  /// 它的 activate() 只做一次 Win32 `SetCursor`（使用预加载缓存的 HCURSOR），
  /// 不经过 Flutter 引擎的 `setCustomCursor` 平台通道，也不会创建新的
  /// HCURSOR，因此不会在 Windows 按住左键拖动（SetCapture 状态）时
  /// 造成消息循环卡死。
  ///
  /// 虽然赋值 `mouseCursor` 会触发 Flame 的 refreshWidget() 重建
  /// GameWidget，但由于 GameCursor.activate() 本身是零开销的纯内存操作，
  /// 重建过程不再有实际危害。
  set cursorState(MouseCursorState state) {
    // 避免重复赋值触发不必要的 widget 重建
    if (_currentCursorState == state) return;
    _currentCursorState = state;

    mouseCursor = switch (state) {
      MouseCursorState.normal => GameCursors.normal,
      MouseCursorState.click => GameCursors.hovered,
      MouseCursorState.drag => GameCursors.dragged,
      MouseCursorState.press => GameCursors.pressed,
      MouseCursorState.talk => const GameCursor(name: Cursors.talk),
      MouseCursorState.sandglass => const GameCursor(name: Cursors.sandglass),
    };
  }
}
