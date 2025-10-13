import 'package:flutter/foundation.dart';

class MeetingState with ChangeNotifier {
  bool showMeeting = false;
  List<dynamic> people = [];

  void update([List<dynamic>? newPeople]) {
    if (people != newPeople) {
      people = newPeople ?? [];
      showMeeting = newPeople != null && newPeople.isNotEmpty;
      notifyListeners();
    }
  }
}
