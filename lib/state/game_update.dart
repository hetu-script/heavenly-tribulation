import 'package:flutter/foundation.dart';

import '../game/logic.dart';

class GameTimestampState with ChangeNotifier {
  String datetimeString = '';
  int timestamp = 0;

  void update() {
    final (timestamp, datetimeString) = GameLogic.calculateTimestamp();
    this.timestamp = timestamp;
    this.datetimeString = datetimeString;
    notifyListeners();
  }

  (int, String) get() {
    return (timestamp, datetimeString);
  }
}
