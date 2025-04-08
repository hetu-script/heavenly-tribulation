import 'package:flutter/foundation.dart';

import '../engine.dart';

class CursorState with ChangeNotifier {
  String? cursor;

  void set(String name) async {
    if (cursor == name) return;
    assert(engine.config.cursors.containsKey(name), 'Cursor $name not found!');
    cursor = name;
    await engine.setCursor(name);
    notifyListeners();
  }
}
