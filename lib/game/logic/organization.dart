part of 'logic.dart';

// 每个月 5 日前，门派成员需要前往指定场景开会。
// 对于总管或以下的职位，需要前往自己所属的据点的会堂场景。
// 对于堂主或以上的职位，需要前往门派总堂所在据点的门派场景。
// 门派每月例会分为 7 个部分：
// 1，重大事件通报，新的联盟和敌对关系、新门派建立。
// 2，特殊仪式或庆典：新成员加入、师徒结对、成员境界突破或陨落、出关仪式。
// 3，总结上个月任务完成情况，进行物品赏赐，以及功勋加减。
// 4，据点总管宣布一些重要决定，如内政策略，赏赐成员，驱逐功勋过低的成员，门派迁移。
//    这些决定成员可以发表自己的意见。总管以上成员可以投票。
// 5，玩家可以提出个人请求，要求晋升，以及获得修炼资源等。
// 6，发布本月门派任务，每次会有三个，玩家可以自由选择其中一个领取。
// 7，会议结束
Future<void> _monthlyMeeting(
    dynamic superior, dynamic location, dynamic organization) async {
  final bool hasAttendedAnyMeeting =
      GameData.flags['organizations'][organization['id']] == true;
  // if (!hasAttendedAnyMeeting) {
  //   GameData.flags['organizations'][organization['id']]
  //       ['hasAttendedAnyMeeting'] = true;
  // }

  dialog.pushDialog('journal_organizationInitiation_meeting_intro_1',
      npcId: 'servant');
  dialog.pushDialog('journal_organizationInitiation_meeting_intro_2',
      character: superior);

  final people = [superior];

  final membersAtLocationData =
      organization['membersData'].values.where((data) {
    return data['id'] != GameData.hero['id'] &&
        data['id'] != superior['id'] &&
        data['reportSiteId'] == location['id'];
  }).toList();
  membersAtLocationData.shuffle();

  people.addAll(membersAtLocationData.take(3));
  people.add(GameData.hero);
  engine.context.read<MeetingState>().update(people);

  if (!hasAttendedAnyMeeting) {
  } else {}
}
