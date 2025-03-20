import 'package:flutter/foundation.dart';

import '../engine.dart';

class GameTimestampState with ChangeNotifier {
  String gameDateTimeString = '';
  int gameTimestamp = 0;

  void update() {
    gameDateTimeString = engine.hetu.invoke('getCurrentDateTimeString');
    gameTimestamp = engine.hetu.invoke('getTimestamp');
    notifyListeners();
  }

  (String, int) get() {
    return (gameDateTimeString, gameTimestamp);
  }
}
