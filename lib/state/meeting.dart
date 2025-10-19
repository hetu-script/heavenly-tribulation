import 'package:flutter/foundation.dart';

// import '../game/game.dart';

class MeetingState with ChangeNotifier {
  bool showMeeting = false;
  List<dynamic> people = [];
  bool showExitButton = false;

  void update([List<dynamic>? newPeople]) {
    if (people != newPeople) {
      people = newPeople ?? [];
      showMeeting = newPeople != null && newPeople.isNotEmpty;
      notifyListeners();
    }
  }

  void remove(dynamic character) {
    people.remove(character);
    // if (people.isEmpty || (people.length == 1 && people[0] == GameData.hero)) {
    //   showMeeting = false;
    // }
    notifyListeners();
  }

  void end() {
    showExitButton = true;
    notifyListeners();
  }
}
