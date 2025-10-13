part of 'logic.dart';

Future<void> _monthlyMeeting(
    dynamic superior, dynamic location, dynamic organization) async {
  final membersData = organization['membersData'];
  final membersAtLocation = membersData.values.where((data) =>
      data['reportSiteId'] == location['id'] &&
      data['id'] != GameData.hero['id']);
  final meetingPeople = [superior, ...membersAtLocation];

  engine.context.read<MeetingState>().update(meetingPeople);

  final bool hasAttendedAnyMeeting = GameData.flags['organizations']
          [organization['id']]['hasAttendedAnyMeeting'] ==
      true;

  if (!hasAttendedAnyMeeting) {
    GameData.flags['organizations'][organization['id']]
        ['hasAttendedAnyMeeting'] = true;

    final people = [superior];

    final membersData = organization['membersData'].where((data) {
      return data['id'] != GameData.hero['id'] &&
          data['id'] != superior['id'] &&
          data['reportSiteId'] == location['id'];
    });

    people.addAll(membersData.take(3));

    people.add(GameData.hero);

    engine.context.read<MeetingState>().update(people);
  }
}
