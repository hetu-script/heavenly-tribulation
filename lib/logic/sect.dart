part of 'logic.dart';

const _kManagingTitles = {'manager', 'mayor', 'governor'};

/// 组织月度更新
void _updateSectMonthly(dynamic sect, {bool force = false}) {
  // engine.debug('${sect['id']} 的月度更新');

  engine.hetu.invoke('resetSectMonthly', positionalArgs: [sect]);
  if (force) {
    sect['flags']['monthly']['updated'] = true;
  }
}

// 每个月 5 日前，门派成员需要前往指定场景开会。
// 对于总管或以下的职位，需要前往自己所属的城市的会堂场景。
// 对于堂主或以上的职位，需要前往门派总堂所在城市的门派场景。
// 门派每月例会分为 7 个部分：
// 1，事件通报：新的联盟和敌对关系、新门派建立。
// 2，仪式庆典：新成员加入、师徒结对、成员境界突破或陨落、出关仪式。
// 3，上月总结：任务完成情况，进行物品赏赐，以及功勋加减。
// 4，内政沟通：如内政策略，赏赐成员，驱逐功勋过低的成员，门派迁移。
//    这些决定成员可以发表自己的意见。总管以上成员可以投票。
// 5，个人请求：要求晋升，以及获得修炼资源等。
// 6，门派任务：每次会有三个，玩家可以自由选择其中一个领取。
// 7，会议结束
// 门派会议上只处理玩家角色自己的相关数值变化
// NPC 角色的数值变化另外由 updateSectMonthly 处理。
Future<void> _showMeeting(
    dynamic sect, dynamic location, dynamic superior) async {
  final heroId = GameData.hero['id'];
  final heroMemberData = sect['membersData'][heroId];
  final heroJobRank = heroMemberData['rank'];

  engine.hetu.invoke('characterMet', positionalArgs: [
    superior,
    GameData.hero,
  ]);
  final people = [superior];
  final membersAtLocationData = sect['membersData']
      .values
      .where((data) {
        return data['id'] != heroId &&
            data['id'] != superior['id'] &&
            data['superiorId'] == superior['id'];
      })
      .map((data) => GameData.getCharacter(data['id']))
      .toList();
  membersAtLocationData.shuffle();
  final otherMembers = membersAtLocationData.take(3);
  for (final member in otherMembers) {
    engine.hetu.invoke('characterMet', positionalArgs: [
      member,
      GameData.hero,
    ]);
  }
  people.addAll(otherMembers);
  people.add(GameData.hero);

  dialog.pushDialog(
    'sect_meeting_intro_1',
    npcId: location['npcId'],
    interpolations: [
      sect['name'],
      location['name'],
    ],
  );
  dialog.pushBackground('black.png', isFadeIn: true);
  dialog.pushTask(() async {
    await Future.delayed(const Duration(milliseconds: 500));
    engine.context.read<MeetingState>().update(people);
  });
  dialog.popBackground(isFadeOut: true);
  dialog.pushDialog('sect_meeting_intro_2', character: superior);
  await dialog.execute();

  final sectMonthly = sect['monthly'] ?? {};

  // 仪式庆典：新成员加入
  final List recruitedThisMonthIds = sectMonthly['recruited'] ?? [];
  bool recruitedHero = recruitedThisMonthIds.contains(heroId);
  if (recruitedHero) {
    recruitedThisMonthIds.remove(heroId);
  }
  List recruitedThisMonth = recruitedThisMonthIds
      .where((id) {
        final charMemberData = sect['membersData'][id];
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
    dialog.pushDialog('sect_meeting_new_recruit_1', character: superior);
    await dialog.execute();

    for (final newRecruit in recruitedThisMonth) {
      if (newRecruit != GameData.hero) {
        final competitive = newRecruit['personality']['competitive'] ?? 0;
        if (competitive > kPersonalityThreshold1) {
          dialog.pushDialog('sect_meeting_new_recruit_option_2_reply',
              character: newRecruit);
        } else if (competitive < -kPersonalityThreshold1) {
          dialog.pushDialog('sect_meeting_new_recruit_option_1_reply',
              character: newRecruit);
        } else {
          dialog.pushDialog('sect_meeting_new_recruit_option_3_reply',
              character: newRecruit);
        }
        await dialog.execute();
      } else {
        dialog.pushDialog('sect_meeting_new_recruit_2', isHero: true);
        await dialog.execute();
        final journal = engine.hetu.invoke('Journal', namedArgs: {
          'id': 'sectFirstMeetingIntroduction',
          'title': engine.locale('journal_sectFirstMeetingIntroduction_title'),
          'stages': [
            engine.locale('sect_meeting_new_recruit_options'),
          ],
        });
        final selected = await GameLogic.promptJournal(journal, selections: [
          'sect_meeting_new_recruit_option_1',
          'sect_meeting_new_recruit_option_2',
          'sect_meeting_new_recruit_option_3',
        ]);
        dialog.pushDialog('${selected}_reply', isHero: true);
        dialog.pushDialog('sect_meeting_new_recruit_3', character: superior);
        await dialog.execute();
      }
    }
  }

  // 上月总结
  final initiationQuest = GameData.hero['journals']['sectInitiation'];

  if (initiationQuest?['stage'] == 1) {
    // 玩家第一次参加门派会议，跳过总结环节
    engine.hetu.invoke('progressJournalById',
        namespace: 'Player', positionalArgs: ['sectInitiation']);
  } else {
    // 并非第一次参加的话，才会有上月总结环节
    final contributionsLastMonth = sect['flags']['monthly']['contributions'];
    dialog.pushDialog('sect_meeting_monthlySummary', character: superior);
    await dialog.execute();

    final heroContributionLastMonth = contributionsLastMonth[heroId] ?? 0;

    if (heroContributionLastMonth >= _kSectExpectedMonthlyContribution) {
      dialog.pushDialog(
        'sect_meeting_monthlySummary_contribution_bonus',
        character: superior,
        interpolations: [GameData.hero['name']],
      );
      await dialog.execute();

      final reward = engine.hetu.invoke('createReward', namedArgs: {
        'genre': sect['genre'],
        'details': {
          'craftMaterial': {
            'amount': heroJobRank * (heroJobRank + 1) + 1,
          },
        },
      });
      await engine.hetu
          .invoke('acquireAll', namespace: 'Player', positionalArgs: [
        reward,
      ]);
      await GameLogic.promptItems(reward);
    } else {
      dialog.pushDialog(
        'sect_meeting_monthlySummary_contribution_normal',
        character: superior,
        interpolations: [GameData.hero['name']],
      );
      await dialog.execute();
    }
  }

  // 新的门派任务
  dialog.pushDialog('sect_meeting_quests', character: superior);
  await dialog.execute();

  final quests = engine.hetu
      .invoke('generateSectQuests', positionalArgs: [sect, location]);

  final quest = await showDialog(
    context: engine.context,
    barrierDismissible: false,
    builder: (context) => QuestView(
      quests: quests,
      showCloseButton: false,
    ),
  );

  await GameLogic.heroAcquireQuest(quest, location, sect);

  final newTitleId = engine.hetu.invoke('checkCharacterTitle',
      positionalArgs: [GameData.hero], namedArgs: {'setAsManager': true});
  if (newTitleId != null) {
    dialog.pushDialog('sect_meeting_monthlySummary_promotion',
        character: superior,
        interpolations: [
          GameData.hero['name'],
          engine.locale(newTitleId),
        ]);
    await dialog.execute();
    engine.hetu.invoke(
      'setCharacterTitle',
      positionalArgs: [GameData.hero, newTitleId],
      namedArgs: {
        'sect': sect,
        'autoManagningSite': false,
      },
    );
    if (_kManagingTitles.contains(newTitleId)) {
      switch (newTitleId) {
        case 'manager':
          dialog.pushDialog('sect_promotion_manager', character: superior);
          await dialog.execute();
          final sites = (sect['locationIds'] as Iterable)
              .map((id) => GameData.getLocation(id))
              .where(
                (loc) =>
                    loc['category'] == 'site' &&
                    kSiteKindsManagable.containsKey(loc['kind']) &&
                    loc['kind'] != kLocationKindHeadquarters &&
                    loc['kind'] != kLocationKindCityhall &&
                    loc['managerId'] == null,
              );
          assert(sites.isNotEmpty);
          final managingSiteId = await GameLogic.selectLocation(datas: sites);
          final managingSite = GameData.getLocation(managingSiteId);
          managingSite['managerId'] = heroId;
          if (!GameData.hero['managingLocationIds']
              .contains(managingSite['id'])) {
            GameData.hero['managingLocationIds'].add(managingSite['id']);
          }
        case 'mayor':
          dialog.pushDialog('sect_promotion_mayor', character: superior);
          await dialog.execute();
          final cities = (sect['locationIds'] as Iterable)
              .map((id) => GameData.getLocation(id))
              .where((loc) =>
                  loc['category'] == 'city' && loc['managerId'] == null);
          assert(cities.isNotEmpty);
          final managingCityId = await GameLogic.selectLocation(datas: cities);
          final managingCity = GameData.getLocation(managingCityId);
          managingCity['managerId'] = heroId;
          GameData.hero['managingLocationIds'].clear();
          GameData.hero['managingLocationIds'].add(managingCity['id']);
          engine.hetu.invoke('setCharacterHome',
              positionalArgs: [GameData.hero, managingCity]);
        case 'governor':
          dialog.pushDialog('sect_promotion_governor', character: superior);
          await dialog.execute();
          final cities = (sect['locationIds'] as Iterable)
              .map((id) => GameData.getLocation(id))
              .where((loc) =>
                  loc['category'] == 'city' && loc['managerId'] == null);
          assert(cities.isNotEmpty);
          final managingCityId = await GameLogic.selectLocation(datas: cities);
          final managingCity = GameData.getLocation(managingCityId);
          managingCity['managerId'] = heroId;
          if (!GameData.hero['managingLocationIds']
              .contains(managingCity['id'])) {
            GameData.hero['managingLocationIds'].add(managingCity['id']);
          }
      }
      final newSuperiorId =
          engine.hetu.invoke('assignCharacterSuperior', positionalArgs: [
        GameData.hero,
        sect,
      ]);
      if (newSuperiorId != superior['id']) {
        final newSuperior = GameData.getCharacter(newSuperiorId);
        dialog.pushDialog('sect_meeting_monthlySummary_newSuperior',
            character: newSuperior, interpolations: [newSuperior['name']]);
      }
    }
  }

  dialog.pushDialog('sect_meeting_ending', character: superior);
  await dialog.execute();

  engine.context.read<MeetingState>().end();

  _updateSectMonthly(sect, force: true);
}
