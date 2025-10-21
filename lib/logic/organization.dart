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
Future<void> _showMeeting(
  dynamic superior,
  dynamic location,
  dynamic organization, {
  bool isFirstMeeting = false,
}) async {
  final people = [superior];
  final membersAtLocationData = organization['membersData']
      .values
      .where((data) {
        return data['id'] != GameData.hero['id'] &&
            data['id'] != superior['id'] &&
            data['reportSiteId'] == location['id'];
      })
      .map((data) => GameData.getCharacter(data['id']))
      .toList();
  membersAtLocationData.shuffle();
  final members = membersAtLocationData.take(3);
  for (final member in members) {
    engine.hetu.invoke('characterMet', positionalArgs: [
      member,
      GameData.hero,
    ]);
  }
  people.addAll(members);
  people.add(GameData.hero);

  dialog.pushDialog(
    'organization_meeting_intro_1',
    npcId: 'servant',
    interpolations: [
      organization['name'],
      location['name'],
    ],
  );
  dialog.pushBackground('black.png', isFadeIn: true);
  dialog.pushTask(() async {
    await Future.delayed(const Duration(milliseconds: 500));
    engine.context.read<MeetingState>().update(people);
  });
  dialog.popBackground(isFadeOut: true);
  dialog.pushDialog('organization_meeting_intro_2', character: superior);
  await dialog.execute();

  final organizationMonthly = organization['monthly'] ?? {};

  // 新人见面环节
  final List recruitedThisMonthIds = organizationMonthly['recruited'] ?? [];
  bool recruitedHero = recruitedThisMonthIds.contains(GameData.hero['id']);
  if (recruitedHero) {
    recruitedThisMonthIds.remove(GameData.hero['id']);
  }
  List recruitedThisMonth = recruitedThisMonthIds
      .where((id) {
        final charMemberData = organization['membersData'][id];
        return charMemberData['reportSiteId'] == location['id'];
      })
      .map((id) => GameData.getCharacter(id))
      .toList();
  recruitedThisMonth.shuffle();
  if (recruitedHero) {
    recruitedThisMonth = recruitedThisMonth.take(2).toList();
    recruitedThisMonth.add(GameData.hero);
  } else {
    recruitedThisMonth = recruitedThisMonth.take(3).toList();
  }
  if (recruitedThisMonth.isNotEmpty) {
    dialog.pushDialog('organization_meeting_new_recruit_1',
        character: superior);
    await dialog.execute();

    for (final newRecruit in recruitedThisMonth) {
      if (newRecruit != GameData.hero) {
        final competitive = newRecruit['personality']['competitive'] ?? 0;
        if (competitive > kPersonalityThreshold1) {
          dialog.pushDialog('organization_meeting_new_recruit_option_2_reply',
              character: newRecruit);
        } else if (competitive < -kPersonalityThreshold1) {
          dialog.pushDialog('organization_meeting_new_recruit_option_1_reply',
              character: newRecruit);
        } else {
          dialog.pushDialog('organization_meeting_new_recruit_option_3_reply',
              character: newRecruit);
        }
        await dialog.execute();
      } else {
        dialog.pushDialog('organization_meeting_new_recruit_2', isHero: true);
        await dialog.execute();
        final journal = engine.hetu.invoke('Journal', namedArgs: {
          'id': 'organizationFirstMeetingIntroduction',
          'title': engine
              .locale('journal_organizationFirstMeetingIntroduction_title'),
          'stages': [
            engine.locale('organization_meeting_new_recruit_options'),
          ],
        });
        final selected = await GameLogic.promptJournal(journal, selections: [
          'organization_meeting_new_recruit_option_1',
          'organization_meeting_new_recruit_option_2',
          'organization_meeting_new_recruit_option_3',
        ]);
        dialog.pushDialog('${selected}_reply', isHero: true);
        dialog.pushDialog('organization_meeting_new_recruit_3',
            character: superior);
        await dialog.execute();
      }
    }
  }

  // 新的门派任务
  dialog.pushDialog('organization_meeting_quests', character: superior);
  await dialog.execute();

  final quests = engine.hetu.invoke('generateOrganizationQuests',
      positionalArgs: [organization, location]);

  final quest = await showDialog(
    context: engine.context,
    barrierDismissible: false,
    builder: (context) => QuestView(
      quests: quests,
      showCloseButton: false,
    ),
  );

  await GameLogic.acquireQuest(quest, location, organization);

  dialog.pushDialog('organization_meeting_ending', character: superior);
  await dialog.execute();

  engine.context.read<MeetingState>().end();
}
