part of 'logic.dart';

void _updateLocationDaily(dynamic location) {
  final updateStatus = location['updateStatus'];
  final cost = updateStatus?['cost'];
  if (cost == null) return;

  if (updateStatus['isPaused'] == true) return;

  for (final materialId in cost.keys) {
    final int requiredAmount = cost[materialId] ?? 0;
    assert(requiredAmount > 0);
    int exhausted = engine.hetu.invoke('entityExhaust', positionalArgs: [
      location,
      materialId,
      requiredAmount
    ], namedArgs: {
      'onStorage': true,
    });
    if (exhausted == 0) {
      // 资源不足，暂停运转
      updateStatus['isPaused'] = true;
      engine.warning(
          '${location['name']} 暂停运行，缺少资源: ${engine.locale(materialId)}');
      break;
    }
  }
  if (updateStatus['isPaused'] == true) return;

  final isDeveloping = updateStatus['isDeveloping'] ?? false;
  if (isDeveloping) {
    updateStatus['progress'] += 1;

    if (updateStatus['progress'] == updateStatus['max']) {
      engine.hetu
          .invoke('resetLocationUpdateStatus', positionalArgs: [location]);

      location['development'] += 1;
      final development = location['development'];

      if (location['kind'] == 'headquarters') {
        // 门派总部扩建完成，提升门派最大城市数量
        final sect = GameData.getSect(location['sectId']);
        sect['development'] = development;
        final maxCityCount =
            GameLogic.maxCityCountForSectDevelopment(development);
        sect['maxCityCount'] = maxCityCount;
        engine.warning(
            '门派 ${sect['name']} 的规模扩大到了 [$development] 最大城市数量提升到了 [$maxCityCount]');
      } else if (location['category'] == 'city') {
        // 城市扩建完成，提升最大建筑数量
        final maxSiteCount = GameLogic.calculateMaxSiteCountForCity(location);
        final city = GameData.getLocation(location['atCityId']);
        city['development'] = development;
        city['maxSiteCount'] = maxSiteCount;
        engine.warning(
            '${city['name']} 的规模扩大到了 [$development] 最大建筑数量提升到了 [$maxSiteCount]');
      } else {
        engine.warning('${location['name']} 的规模提升到了 $development');
      }
    }
  }
}

/// 城市月度更新
void _updateLocationMonthly(dynamic location, {bool force = false}) {
  if (location['flags']['monthly']['updated'] == true && !force) return;

  engine.hetu.invoke('resetLocationMonthly', positionalArgs: [location]);
  if (force) {
    location['flags']['monthly']['updated'] = force;
  }

  final kind = location['kind'];

  if (location['category'] == 'city') {
  } else if (location['category'] == 'site') {
    if (kSiteKindsManagable.containsKey(kind)) {
      engine.hetu.invoke('replenishStorage', positionalArgs: [location]);
    }

    // 交易类场景每个月刷新物品
    switch (location['kind']) {
      case 'cityhall':
        engine.hetu.invoke('replenishBounty', positionalArgs: [location]);
      case 'tradinghouse':
        engine.hetu.invoke('replenishTradingMoney', positionalArgs: [location]);
        engine.hetu
            .invoke('replenishTradingMaterials', positionalArgs: [location]);
        engine.hetu.invoke('replenishTradingItem', positionalArgs: [location]);
      case 'library' || 'auctionhouse' || 'alchemylab' || 'runelab':
        engine.hetu.invoke('replenishTradingMoney', positionalArgs: [location]);
        engine.hetu.invoke('replenishTradingItem', positionalArgs: [location]);
      case 'farmland' || 'fishery' || 'timberland' || 'huntingground' || 'mine':
        engine.hetu.invoke('replenishTradingMoney', positionalArgs: [location]);
        engine.hetu
            .invoke('replenishProductionMaterials', positionalArgs: [location]);
      case 'exparray':
        engine.hetu
            .invoke('replenishCollectableLight', positionalArgs: [location]);
    }
  }
}

/// 异步函数，在显示场景窗口之前执行
Future<dynamic> _tryEnterLocation(dynamic location) async {
  engine.info('尝试进入城市 [${location['name']}]');
  // [result] 值是 true 意味着不会进入场景
  final result = await engine.hetu.invoke('onGameEvent',
      positionalArgs: ['onBeforeEnterLocation', location]);
  if (GameLogic.truthy(result)) return;

  engine.context.read<ViewPanelState>().clearAll();

  await GameLogic.updateGame(ticks: (kTicksPerTime ~/ kBaseMoveSpeedOnPlain));
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

  dialog.pushDialog(
    'hint_sectFacilityNotMember',
    npcId: location['npcId'],
  );
  await dialog.execute();

  final siteKind = location['kind'];
  assert(kSiteRentMoneyCostByDay.containsKey(siteKind),
      'Rent cost not defined for site kind: $siteKind');
  final int rentCostRaw = kSiteRentMoneyCostByDay[siteKind]!;
  final int shardPrice = kMaterialPrice['shard']!;
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
  final materialName = engine.locale(materialId);

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
    final cost = _kBasicDungeonShardCost;

    dialog.pushDialog(
      'hint_dungeon_cost',
      npcId: location['npcId'],
      interpolations: [cost],
    );
    await dialog.execute();

    dialog.pushSelectionRaw({
      'id': 'dungeonBasicCost',
      'selections': {
        'pay_shard': engine.locale('pay_shard', interpolations: [cost]),
        'forgetIt': engine.locale('forgetIt'),
      }
    });
    await dialog.execute();
    final selected = dialog.checkSelected('dungeonBasicCost');
    if (selected == null || selected == 'forgetIt') return;

    engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
      'shard',
      cost,
    ]);
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

/// 和门派总堂的聚灵阵交互
/// 如果并非此组织成员，无法使用
void _onInteractExpArray(
  dynamic sect, {
  dynamic location,
}) async {
  final isRented = await _checkRented(location);
  if (!isRented) return;

  engine.pushScene(Scenes.cultivation, arguments: {
    'location': location,
    'enableCultivate': true,
  });
}

/// 和门派藏书阁的功法图录交互
/// 如果并非此组织成员，无法使用
void _onInteractCardLibraryDesk({
  dynamic sect,
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
