import 'package:flutter/foundation.dart';

// import '../game/game.dart';

const kMeetingPeopleMax = 7;

class MeetingState with ChangeNotifier {
  bool showMeeting = false;
  List<dynamic> people = [];
  bool showExitButton = false;

  void update(List<dynamic> newPeople) {
    assert(newPeople.isNotEmpty && newPeople.length <= kMeetingPeopleMax);
    people = newPeople;
    notifyListeners();
  }

  void remove(dynamic character) {
    assert(people.contains(character));
    people.remove(character);
    notifyListeners();
  }

  void end() {
    showExitButton = true;
    notifyListeners();
  }

  void clear() {
    showMeeting = false;
    people = [];
    showExitButton = false;
    notifyListeners();
  }
}
