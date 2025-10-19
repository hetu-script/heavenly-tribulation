part of 'logic.dart';

Future<bool> _checkRented(dynamic location,
    {bool perAvailableDaysTillMonthEnd = true}) async {
  final locationId = location['id'];
  if (location['organizationId'] == null ||
      location['organizationId'] == GameData.hero['organizationId'] ||
      GameData.checkMonthly(MonthlyActivityIds.rented, locationId)) {
    return true;
  }

  dialog.pushDialog(
    'hint_organizationFacilityNotMember',
    name: engine.locale('servant'),
    icon: 'illustration/npc/servant_head.png',
    image: 'illustration/npc/servant.png',
  );
  await dialog.execute();

  final siteKind = location['kind'];
  assert(kSiteRentMoneyCostByDay.containsKey(siteKind),
      'Rent cost not defined for site kind: $siteKind');
  final int rentCostRaw = kSiteRentMoneyCostByDay[siteKind]!;
  final int shardPrice = kMaterialBasePrice['shard']!;
  bool useShard = rentCostRaw >= shardPrice;
  int rentCost = rentCostRaw;
  final int availableDays = kDaysPerMonth - GameLogic.day;
  final int development = location['development'] ?? 0;
  rentCost *= (development + 1);
  if (perAvailableDaysTillMonthEnd) {
    rentCost *= (availableDays + 1);
  }
  if (useShard) {
    rentCost = (rentCost / shardPrice).ceil();
  }
  final materialId = useShard ? 'shard' : 'money';
  final materialName = engine.locale(useShard ? 'shard' : 'money');

  dialog.pushSelectionRaw(
    {
      'id': 'rentQuery',
      'selections': {
        'rentFacility': {
          'text': engine.locale('rentFacility'),
          'description': engine.locale(
            'rentFacility_description',
            interpolations: [
              rentCost,
              materialName,
            ],
          ),
        },
        'forgetIt': engine.locale('forgetIt'),
      },
    },
  );
  await dialog.execute();
  final selected = dialog.checkSelected('rentQuery');
  if (selected != 'rentFacility') return false;
  bool success = engine.hetu.invoke(
    'exhaust',
    namespace: 'Player',
    positionalArgs: [materialId, rentCost],
  );
  if (success) {
    engine.play('coins-31879.mp3');
    GameData.addPlayerMonthly(MonthlyActivityIds.rented, locationId);
    dialog.pushDialog(
      'hint_rentedFacility',
      name: engine.locale('servant'),
      icon: 'illustration/npc/servant_head.png',
      image: 'illustration/npc/servant.png',
    );
    await dialog.execute();
    return true;
  } else {
    dialog.pushDialog(
      'hint_notEnough',
      name: engine.locale('servant'),
      icon: 'illustration/npc/servant_head.png',
      image: 'illustration/npc/servant.png',
      interpolations: [materialName],
    );
    await dialog.execute();
    return false;
  }
}

/// 和秘境入口交互
/// 秘境在生成时，会随机产生一个开放月份，只有在开放月份时才能进入。
/// 秘境如果被某个门派占领，则非门派成员无法进入。
/// 秘境进入时可以选择境界。无境界无需门票。凝气期以上则需要支付对应境界的秘境石。
void _onInteractDungeonEntrance({
  dynamic organization,
  dynamic location,
}) async {
  dialog.pushSelection('dungeonEntrance', [
    'about_dungeon',
    'enter_common_dungeon',
    'enter_advanced_dungeon',
    'cancel',
  ]);
  await dialog.execute();
  final selected = dialog.checkSelected('dungeonEntrance');
  if (selected == 'cancel') return;

  if (selected == 'about_dungeon') {
    dialog.pushDialog(
      'hint_dungeonEntrance',
      name: engine.locale('guard'),
      icon: 'illustration/npc/guard_head.png',
      image: 'illustration/npc/guard.png',
    );
    await dialog.execute();
  } else {
    // organization 可能为 null，此时该据点没有被门派占领
    final isRented =
        await _checkRented(location, perAvailableDaysTillMonthEnd: false);
    if (!isRented) return;

    final isBasic = selected == 'enter_common_dungeon';

    if (isBasic) {
      dialog.pushDialog(
        'hint_dungeon_cost',
        name: engine.locale('guard'),
        icon: 'illustration/npc/guard_head.png',
        image: 'illustration/npc/guard.png',
        interpolations: [_kBasicDungeonShardCost],
      );
      await dialog.execute();

      dialog.pushSelectionRaw({
        'id': 'dungeonBasicCost',
        'selections': {
          'pay_shard': engine
              .locale('pay_shard', interpolations: [_kBasicDungeonShardCost]),
          'forgetIt': engine.locale('forgetIt'),
        }
      });
      await dialog.execute();
      final selected = dialog.checkSelected('dungeonBasicCost');
      if (selected == 'forgetIt') return;

      engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
        'shard',
        _kBasicDungeonShardCost,
      ]);
    } else {
      dialog.pushDialog(
        'hint_dungeon_cost2',
        name: engine.locale('guard'),
        icon: 'illustration/npc/guard_head.png',
        image: 'illustration/npc/guard.png',
      );
      await dialog.execute();
    }

    GameLogic.tryEnterDungeon(
      isBasic: isBasic,
      dungeonId: location['dungeonId'] ?? 'dungeon_1',
    );
  }
}

/// 和门派总堂的聚灵阵交互
/// 如果并非此组织成员，无法使用
void _onInteractExpArray(
  dynamic organization, {
  dynamic location,
}) async {
  final isRented = await _checkRented(location);
  if (!isRented) return;

  engine.pushScene(Scenes.cultivation, arguments: {
    'locationId': location['id'],
    'enableCultivate': true,
  });
}

/// 和门派藏书阁的功法图录交互
/// 如果并非此组织成员，无法使用
void _onInteractCardLibraryDesk({
  dynamic organization,
  dynamic location,
}) async {
  final isRented = await _checkRented(location);
  if (!isRented) return;

  engine.pushScene(Scenes.library, arguments: {
    'locationId': location['id'],
    'enableCardCraft': true,
    'enableScrollCraft': true,
  });
}

Future<void> _onAfterEnterLocation(dynamic location) async {
  await engine.hetu.invoke('onGameEvent',
      positionalArgs: ['onAfterEnterLocation', location]);

  if (location['kind'] == 'home') {
    final ownerId = location['ownerId'];
    if (ownerId != GameData.hero['id']) {
      final owner = GameData.getCharacter(ownerId);
      if (owner['locationId'] != location['id']) {
        GameDialogContent.show(
            engine.context,
            engine.locale('hint_visitEmptyHome',
                interpolations: [owner['name']]));
      }
    }
  }

  final heroOrganizationId = GameData.hero['organizationId'];
  if (heroOrganizationId != null) {
    final organization = GameData.getOrganization(heroOrganizationId);
    final memberData = organization['membersData'][GameData.hero['id']];
    assert(memberData != null,
        'Member data not found in organization [${organization['id']}], member id: ${GameData.hero['id']}');
    final reportSiteId = memberData['reportSiteId'];
    if (reportSiteId == location['id']) {
      final superiorId = memberData['superiorId'];
      assert(superiorId != null);
      final superior = GameData.getCharacter(superiorId);
      final organizationInitiationQuest =
          GameData.hero['journals']['organizationInitiation'];
      assert(organizationInitiationQuest != null,
          'Organization initiation quest not found in hero journals');
      if (organizationInitiationQuest['stage'] == 0) {
        engine.hetu.invoke('characterMet', positionalArgs: [
          GameData.hero,
          superior,
        ]);
        dialog.pushDialog(
          'hint_organization_initiation2',
          character: superior,
        );
        await dialog.execute();

        final itemsInfo = [
          {
            'type': 'potion',
            'rank': GameData.hero['rank'],
          },
          {
            'type': 'cardpack',
            'genre': organization['genre'],
            'rank': GameData.hero['rank'],
          },
        ];
        final items = await engine.hetu
            .invoke('loot', namespace: 'Player', positionalArgs: [itemsInfo]);
        GameLogic.promptItems(items);
        engine.hetu.invoke('progressJournalById',
            namespace: 'Player', positionalArgs: ['organizationInitiation']);
        GameLogic.promptJournal(organizationInitiationQuest);
      } else {
        final playerMonthly = GameData.flags['playerMonthly'];
        if (playerMonthly['hasAttendedMeeting'] != true && GameLogic.day <= 5) {
          playerMonthly['hasAttendedMeeting'] = true;

          final isFirstMeeting = organizationInitiationQuest['stage'] == 1;
          if (isFirstMeeting) {
            engine.hetu.invoke('progressJournalById',
                namespace: 'Player',
                positionalArgs: ['organizationInitiation']);
          }
          _monthlyMeeting(superior, location, organization,
              isFirstMeeting: isFirstMeeting);
        }
      }
    }
  }
}
