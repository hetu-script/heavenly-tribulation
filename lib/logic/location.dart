part of 'logic.dart';

/// 异步函数，在显示场景窗口之前执行
Future<dynamic> _tryEnterLocation(dynamic location) async {
  engine.info('尝试进入城市 [${location['name']}]');
  // [result] 值是 true 意味着不会进入场景
  final result = await engine.hetu.invoke('onGameEvent',
      positionalArgs: ['onBeforeEnterLocation', location]);
  if (GameLogic.truthy(result)) return;

  engine.context.read<ViewPanelState>().clearAll();

  await GameLogic.updateGame(ticks: (kTicksPerTime ~/ kBasePlainMoveSpeed));
  engine.pushScene(
    location['id'],
    constructorId: Scenes.location,
    arguments: {'locationId': location['id']},
  );
}

void _tryEnterDungeon({
  int? rank,
  bool isBasic = false,
  String dungeonId = 'dungeon_1',
  bool pushScene = true,
}) async {
  if (isBasic) {
    engine.hetu.invoke('resetDungeon', namedArgs: {
      'rank': rank,
      'isBasic': true,
    });
    if (!pushScene) return;
    engine.pushScene(
      'dungeon_1',
      constructorId: Scenes.worldmap,
      arguments: {
        'id': 'dungeon_1',
        'method': 'load',
      },
    );
  } else {
    final items = await GameLogic.selectItem(
      character: GameData.hero,
      title: engine.locale('selectItem'),
      filter: {
        'category': 'dungeon_ticket',
        'rank': rank,
      },
      multiSelect: false,
    );
    if (items.isNotEmpty) {
      final selectedItem = items.first;
      engine.hetu
          .invoke('lose', namespace: 'Player', positionalArgs: [selectedItem]);
      engine.hetu.invoke('resetDungeon', namedArgs: {
        'rank': selectedItem['rank'],
        'isBasic': false,
      });
      if (!pushScene) return;
      engine.pushScene(
        dungeonId,
        constructorId: Scenes.worldmap,
        arguments: {
          'id': dungeonId,
          'method': 'load',
        },
      );
    }
  }
}

Future<bool> _checkRented(dynamic location,
    {bool perAvailableDaysTillMonthEnd = true}) async {
  final locationId = location['id'];
  if (location['sectId'] == null ||
      location['sectId'] == GameData.hero['sectId'] ||
      GameData.checkMonthly(MonthlyActivityIds.rented, locationId)) {
    return true;
  }

  // 盟友门派的设施免费共享
  final heroSectId = GameData.hero['sectId'];
  if (heroSectId != null) {
    final heroSect = GameData.getSect(heroSectId);
    final locSectId = location['sectId'];
    if (locSectId != null && heroSect != null) {
      final allySectIds = heroSect['allySectIds'] as Iterable?;
      if (allySectIds != null && allySectIds.contains(locSectId)) {
        return true;
      }
      // 敌对门派的设施不可租用
      final enemySectIds = heroSect['enemySectIds'] as Iterable?;
      if (enemySectIds != null && enemySectIds.contains(locSectId)) {
        final locSect = GameData.getSect(locSectId);
        dialog.pushDialog(
          'hint_sect_diplomacy_access_denied',
          npcId: location['npcId'],
          interpolations: [locSect?['name'] ?? '', heroSect['name']],
        );
        await dialog.execute();
        return false;
      }
    }
  }

  dialog.pushDialog('hint_sectFacilityNotMember', npcId: location['npcId']);
  await dialog.execute();

  final siteKind = location['kind'];
  assert(kSiteRentMoneyCostByDay.containsKey(siteKind),
      'Rent cost not defined for site kind: $siteKind');
  int rentCost = kSiteRentMoneyCostByDay[siteKind]!;
  // final int shardPrice = kMaterialPrice['shard']!;
  // bool useShard = rentCostRaw >= shardPrice;
  // int rentCost = rentCostRaw;
  final int availableDays = kDaysPerMonth - GameLogic.day;
  final int development = location['development'] ?? 0;
  rentCost *= (development + 1);
  if (perAvailableDaysTillMonthEnd) {
    rentCost *= (availableDays + 1);
  }
  // if (useShard) {
  //   rentCost = (rentCost / shardPrice).ceil();
  // }
  // final materialId = useShard ? 'shard' : 'money';
  // final materialName = engine.locale(materialId);

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
              engine.locale('money'),
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

  int exhausted = engine.hetu.invoke(
    'exhaust',
    namespace: 'Player',
    positionalArgs: ['money', rentCost],
  );
  if (exhausted == rentCost) {
    engine.play(GameSound.coins);
    GameData.addMonthly(MonthlyActivityIds.rented, locationId);
    dialog.pushDialog(
      'hint_rentedFacility',
      npcId: location['npcId'],
    );
    await dialog.execute();
    return true;
  } else {
    dialog.pushDialog(
      'hint_notEnough',
      npcId: location['npcId'],
      interpolations: [engine.locale('money')],
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
  dynamic sect,
  dynamic location,
}) async {
  // sect 可能为 null，此时该城市没有被门派占领
  final isRented =
      await _checkRented(location, perAvailableDaysTillMonthEnd: false);
  if (!isRented) return;

  final dungeonOptions = [
    'enter_common_dungeon',
  ];
  if (location['development'] > 0) {
    dungeonOptions.add('enter_advanced_dungeon');
  }
  dungeonOptions.add('forgetIt');
  dialog.pushSelection('dungeonEntrance', dungeonOptions);
  await dialog.execute();
  final selected = dialog.checkSelected('dungeonEntrance');
  if (selected == null || selected == 'forgetIt') return;

  if (selected == 'enter_common_dungeon') {
    final cost = _kBasicDungeonMoneyCost;

    dialog.pushDialog(
      'hint_dungeon_cost',
      npcId: location['npcId'],
      interpolations: [cost],
    );
    await dialog.execute();

    dialog.pushSelectionRaw({
      'id': 'dungeonBasicCost',
      'selections': {
        'pay_money': engine.locale('pay_money', interpolations: [cost]),
        'forgetIt': engine.locale('forgetIt'),
      }
    });
    await dialog.execute();
    final selected = dialog.checkSelected('dungeonBasicCost');
    if (selected == null || selected == 'forgetIt') return;

    engine.hetu.invoke('exhaust',
        namespace: 'Player', positionalArgs: ['money', cost]);
  } else if (selected == 'enter_advanced_dungeon') {
    dialog.pushDialog(
      'hint_dungeon_cost2',
      npcId: location['npcId'],
    );
    await dialog.execute();
  }

  GameLogic.tryEnterDungeon(
    isBasic: selected == 'enter_common_dungeon',
    dungeonId: location['dungeonId'] ?? 'dungeon_1',
  );
}

/// 和斗技厅交互: 选择赌注档位，匹配对手，开始战斗
void _onInteractArena({
  dynamic location,
}) async {
  final hero = GameData.hero;
  final int heroRank = hero['rank'];
  final int heroLevel = hero['level'];

  // 确定货币类型和基础赌注
  final String currencyId = heroRank == 0 ? 'money' : 'shard';
  final String currencyName = engine.locale(currencyId);
  final int baseWager = kArenaWagerBase[heroRank] ?? kArenaWagerBase[0]!;

  // 根据角色等级在当前境界中的位置限制可选档位
  // 等级越高，低档可能不可选
  final int minLevel = GameLogic.minLevelForRank(heroRank);
  final int maxLevel = GameLogic.maxLevelForRank(heroRank);
  final double levelRatio = (heroLevel - minLevel) / (maxLevel - minLevel);

  // 构建赌注选项
  final Map<String, dynamic> selections = {};
  int minTier = 0;
  if (levelRatio > 0.66) {
    minTier = 1; // 等级较高，至少中档
  }
  if (levelRatio > 0.9) {
    minTier = 2; // 等级很高，只能高档
  }

  final tierKeys = ['arenaWagerLow', 'arenaWagerMid', 'arenaWagerHigh'];
  for (int i = minTier; i < kArenaWagerMultipliers.length; i++) {
    final multiplier = kArenaWagerMultipliers[i];
    final wager = baseWager * multiplier;
    selections[tierKeys[i]] =
        engine.locale(tierKeys[i], interpolations: [wager, currencyName]);
  }
  selections['forgetIt'] = engine.locale('forgetIt');

  dialog.pushSelectionRaw({
    'id': 'arenaWagerSelect',
    'selections': selections,
  });
  await dialog.execute();
  final selected = dialog.checkSelected('arenaWagerSelect');
  if (selected == null || selected == 'forgetIt') return;

  // 解析选中的档位
  final int tier = tierKeys.indexOf(selected);
  final int multiplier = kArenaWagerMultipliers[tier];
  final int wager = baseWager * multiplier;

  // 检查余额
  final int available = hero['materials'][currencyId] ?? 0;
  if (available < wager) {
    dialog.pushDialog(
      'hint_notEnoughWager',
      npcId: location?['npcId'],
      interpolations: [currencyName],
    );
    await dialog.execute();
    return;
  }

  // 扣除赌注
  engine.hetu.invoke('exhaust',
      namespace: 'Player', positionalArgs: [currencyId, wager]);
  engine.play(GameSound.coins);

  // 匹配对手
  dynamic opponent;
  final heroId = hero['id'];
  final List companionIds = hero['companions'] ?? [];
  final List challengedIds =
      GameData.game['flags']['monthly']['arenaChallenged'] ?? [];

  // 根据赌注档位调整对手等级
  // 低档: 境界最小等级附近；中档: 中间等级；高档: 接近最高等级
  List<int> tierLevels = [
    minLevel + ((maxLevel - minLevel) * 0.3).round(),
    minLevel + ((maxLevel - minLevel) * 0.6).round(),
    minLevel + ((maxLevel - minLevel) * 0.9).round(),
  ];

  int targetMaxLevel = tierLevels[tier];
  int targetMinLevel = tier == 0
      ? minLevel
      : tierLevels[tier - 1] + 1; // 当前档位的最小等级是前一档位的最大等级 + 1

  final candidates =
      (GameData.game['characters'].values as Iterable).where((char) {
    if (char['id'] == heroId) return false;
    if (companionIds.contains(char['id'])) return false;
    if (char['rank'] != heroRank) return false;
    if (char['level'] > targetMaxLevel || char['level'] < targetMinLevel) {
      return false;
    }
    if (challengedIds.contains(char['id'])) return false;
    // 在家的角色
    final homeSiteId = '${char['id']}_$kLocationKindHome';
    return char['locationId'] == homeSiteId;
  }).toList();

  if (candidates.isNotEmpty) {
    candidates.shuffle(GameLogic.random);
    opponent = candidates.first;
    // 记录已挑战过的对手
    GameData.addMonthly(MonthlyActivityIds.arenaChallenged, opponent['id']);
  } else {
    // 没有合适的NPC，生成路人角色
    engine.warning('斗技厅没有找到合适的NPC对手，生成路人角色');

    final strangerNames = [
      'arenaStrangerSanxiu',
      'arenaStrangerYouxia',
      'arenaStrangerLangren',
      'arenaStrangerWuzhe',
    ];
    final prefixes = [
      'arenaPrefixWeak',
      'arenaPrefixUnknown',
      'arenaPrefixStrong',
    ];
    // 前缀和档位（难度）有关
    final prefix = engine.locale(prefixes[tier.clamp(0, 2)]);
    final baseName = engine
        .locale(strangerNames[GameLogic.random.nextInt(strangerNames.length)]);
    final name = '$prefix$baseName';

    // 根据赌注档位调整对手等级
    // 低档: 境界最小等级附近；中档: 中间等级；高档: 接近最高等级
    int enemyLevel =
        GameLogic.random.nextInt(targetMaxLevel - targetMinLevel + 1) +
            targetMinLevel;

    opponent = engine.hetu.invoke('BattleEntity', namedArgs: {
      'rank': heroRank,
      'level': enemyLevel,
      'name': name,
    });
  }

  // 赛前垃圾话环节
  final String challengeType =
      engine.hetu.invoke('getRelationshipType', positionalArgs: [opponent]);
  dialog.pushDialog(
    'arena_greeting_$challengeType',
    npc: opponent,
  );
  await dialog.execute();

  // 发起战斗
  engine.context.read<EnemyState>().show(
    opponent,
    loseOnEscape: true,
    onBattleEnd: (bool battleResult, int roundCount) async {
      if (battleResult) {
        dialog.pushDialog(
          'arena_win_$challengeType',
          npc: opponent,
        );
        dialog.pushDialog(
          'arenaWin',
          interpolations: [wager, currencyName],
        );
        await dialog.execute();

        // 生成斗技场战利品
        // 胜利: 返还赌注 + 获得等额奖金
        final reward = wager * 2;
        // 经验值
        const tierExpRates = [0.08, 0.18, 0.28];
        final int expAmount =
            (GameLogic.expForLevel(heroLevel) * tierExpRates[tier]).round();
        final loot = engine.hetu.invoke('createLoot', positionalArgs: [
          [
            {
              'type': 'exp',
              'amount': expAmount,
            },
            {
              'type': 'material',
              'kind': currencyId,
              'amount': reward,
            },
            {
              'type': 'credit',
              'cityId': location['atCityId'],
              'locationId': location['id'],
              'amount': 1,
            },
          ]
        ]);
        await engine.hetu
            .invoke('acquireAll', namespace: 'Player', positionalArgs: [loot]);
        await GameLogic.promptItems(loot);
      } else {
        dialog.pushDialog(
          'arena_lose_$challengeType',
          npc: opponent,
        );
        await dialog.execute();
        dialog.pushDialog(
          'arenaLose',
          interpolations: [wager, currencyName],
        );
        await dialog.execute();
      }
    },
  );
}

/// 和门派总堂的聚灵阵交互
/// 如果并非此组织成员，无法使用
void _onInteractDaoStele(
  dynamic sect, {
  dynamic location,
}) async {
  final isRented = await _checkRented(location);
  if (!isRented) return;

  engine.pushScene(Scenes.cultivation, arguments: {
    'location': location,
  });
}

/// 和聚灵阵交互
/// 如果并非此组织成员，无法使用
void _onInteractExpArray(
  dynamic sect, {
  dynamic location,
}) async {
  final isRented = await _checkRented(location);
  if (!isRented) return;

  engine.pushScene(Scenes.cultivation, arguments: {
    'location': location,
  });
}

/// 和门派藏书阁的功法图录交互
/// 如果并非此组织成员，无法使用
Future<void> _onInteractCardLibraryDesk({
  dynamic sect,
  dynamic location,
}) async {
  final isRented = await _checkRented(location);
  if (!isRented) return;

  engine.pushScene(Scenes.library, arguments: {
    'location': location,
    'enableCardCraft': true,
    'enableScrollCraft': false,
  });
}

Future<void> _onInteractAlchemyFurnace({dynamic location}) async {
  final isRented = await GameLogic.checkRented(location);
  if (!isRented) return;

  engine.context.read<ViewPanelState>().toogle(
    ViewPanels.alchemy,
    arguments: {'location': location},
  );
}

Future<void> _onInteractRunelabWorkbench({dynamic location}) async {
  final isRented = await GameLogic.checkRented(location);
  if (!isRented) return;

  engine.pushScene(Scenes.library, arguments: {
    'enableScrollCraft': true,
  });
}

Future<void> _onAfterEnterLocation(dynamic location) async {
  final result = await engine.hetu.invoke('onGameEvent',
      positionalArgs: ['onAfterEnterLocation', location]);
  if (result == true) {
    return;
  }

  final managerId = location['managerId'];
  if (location['kind'] == 'home') {
    if (managerId != GameData.hero['id']) {
      final manager = GameData.getCharacter(managerId);
      if (manager['locationId'] != location['id']) {
        dialog.pushDialog('hint_visitEmptyHome',
            interpolations: [manager['name']]);
        await dialog.execute();
        engine.popScene(clearCache: true);
      }
    }
  }
}

Map<String, int> _calculateLocationDevelopmentCost(dynamic location) {
  assert(
      location['category'] == 'site', 'develop operation have to be on site');

  final siteKind = location['kind'];
  final int development = location['development'];

  /// TODO: 角色技能会影响开发所需时间
  int days;
  if (siteKind == 'headquarters') {
    days = kSectDevelopmentDaysBase;
  } else if (siteKind == 'cityhall') {
    days = kCityDevelopmentDaysBase;
  } else {
    days = kSiteDevelopmentDaysBase;
  }

  days = days * (development + 1);

  Map<String, int> developmentCost = {'days': days};

  assert(kSiteKindsManagable.containsKey(siteKind));
  final costData = kSiteKindsManagable[siteKind]!['developmentCost']!;
  for (final entry in costData.entries) {
    developmentCost[entry.key] = entry.value * (development + 1) * days;
  }

  return developmentCost;
}

bool _tryStartLocationDevelopment(dynamic location, {Map<String, int>? cost}) {
  final status = location['updateStatus'];
  if (status['isDeveloping'] == true) {
    engine.error('${location['name']} 已经在扩建中！');
    return false;
  }

  cost ??= _calculateLocationDevelopmentCost(location);
  final int days = cost['days']!;

  for (final materialId in cost.keys) {
    if (materialId == 'days') continue;

    final requiredAmount = cost[materialId] ?? 0;
    final availableAmount = location['storage'][materialId] ?? 0;

    if (availableAmount < requiredAmount) {
      dialog.pushDialog(
        'hint_storageNotEnough',
        npcId: location['npcId'],
        interpolations: [
          engine.locale(materialId),
        ],
      );
      dialog.execute();
      return false;
    }
  }

  status['isDeveloping'] = true;
  status['progress'] = 0;
  status['max'] = days;

  final siteKind = location['kind'];
  assert(kSiteKindsManagable.containsKey(siteKind));
  final costData = kSiteKindsManagable[siteKind]!['developmentCost']!;

  status['cost'] = utils.deepCopy(costData);

  dialog.pushDialog(
    'hint_developmentStarted',
    npcId: location['npcId'],
    interpolations: [days],
  );
  dialog.execute();
  return true;
}

Future<void> _cancelLocationDevelopment(dynamic location) async {
  final status = location['updateStatus'];
  if (status['isDeveloping'] != true) {
    engine.error('${location['name']} 并未在扩建中！');
    return;
  }

  dialog.pushDialog('hint_cancelDevelopment', npcId: location['npcId']);
  dialog.pushSelection('cancelDevelopment', [
    'confirm',
    'forgetIt',
  ]);
  await dialog.execute();
  final selected = dialog.checkSelected('cancelDevelopment');
  if (selected != 'confirm') return;

  engine.hetu.invoke('resetLocationUpdateStatus', positionalArgs: [location]);
}
