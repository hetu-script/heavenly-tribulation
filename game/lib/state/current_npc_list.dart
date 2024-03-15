import 'package:flutter/foundation.dart';

class CurrentNpcList with ChangeNotifier {
  Iterable<dynamic> characters = [];

  void updated(Iterable<dynamic> characters) {
    this.characters = characters;
    notifyListeners();
  }
}
