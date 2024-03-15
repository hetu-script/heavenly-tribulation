import 'package:flutter/foundation.dart';

enum MainMenuStates {
  main,
  editor,
  game,
  debug,
}

class MainMenuState with ChangeNotifier {
  MainMenuStates state = MainMenuStates.main;

  void setState(MainMenuStates state) {
    this.state = state;
    notifyListeners();
  }
}
