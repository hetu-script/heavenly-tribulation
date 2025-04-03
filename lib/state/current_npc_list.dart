import 'package:flutter/foundation.dart';

class NpcListState with ChangeNotifier {
  Iterable<dynamic> npcs = [];

  void update([Iterable<dynamic> characters = const []]) {
    npcs = characters;
    notifyListeners();
  }
}
