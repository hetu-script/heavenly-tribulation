part of 'logic.dart';

Future<void> _updateCharactersAtWorldMapPosition() async {
  // 此时不处于大地图场景，根据时间差直接更新角色位置。
  for (final character in GameData.game['characters'].values) {
    if (character['locationId'] != null) continue;
    final worldPosition = character['worldPosition'];
    if (worldPosition == null) continue;
    final moveTo = worldPosition['moveTo'];
    if (moveTo?['route'] == null) continue;
    final route = List<int>.from(moveTo['route']);
    assert(route.isNotEmpty);
    final int timeDiff =
        GameData.game['timestamp'] - moveTo['lastMoveTimestamp'];
    // 默认在山地移动一格消耗 1 个时间单位，平原 1/2 个，水域 1/4 个。
    final tileIndex = route.first;
    final terrain =
        GameData.getTerrainById(tileIndex, worldId: character['worldId']);
    double timeCost;
    if (kTerrainKindsWater.contains(terrain['kind'])) {
      timeCost =
          kTicksPerTime / kBaseWaterMoveSpeed * kBaseNPCMoveSpeedMultiplier;
    } else if (kTerrainKindsMountain.contains(terrain['kind'])) {
      timeCost =
          kTicksPerTime / kBaseMountainMoveSpeed * kBaseNPCMoveSpeedMultiplier;
    } else {
      timeCost =
          kTicksPerTime / kBasePlainMoveSpeed * kBaseNPCMoveSpeedMultiplier;
    }
    if (timeDiff >= timeCost) {
      // 可以移动到下一个地块
      worldPosition['left'] = terrain['left'];
      worldPosition['top'] = terrain['top'];
      moveTo['lastMoveTimestamp'] = GameData.game['timestamp'];
      route.removeAt(0);
      if (route.isEmpty) {
        // 到达目的地
        character['locationId'] = moveTo['locationId'];
        worldPosition['moveTo'] = null;
      }
    }
  }
}

Future<void> _onDying() async {
  if (engine.scene?.id == Scenes.battle) {
    engine.popScene(clearCache: true);
  }
  // engine.clearCachedScene();

  dialog.pushDialog('hint_dying');
  await dialog.execute();

  final int tribulationCount = GameData.hero['tribulationCount'];
  final int tribulationCountMax = GameData.hero['stats']['tribulationCountMax'];

  if (tribulationCountMax > 0 && tribulationCount > tribulationCountMax) {
    // TODO: 展示战败CG
    await engine.clearAllCachedScene(
      except: Scenes.mainmenu,
      triggerOnStart: true,
    );
    return;
  }

  final result =
      await engine.hetu.invoke('onGameEvent', positionalArgs: ['onDying']);
  if (result == true) {
    return;
  }

  engine.setLoading(true, tip: engine.locale('tips_dying'));

  await engine.popSceneTill(GameData.game['mainWorldId'] ?? Scenes.mainmenu);

  final homeLocationId = GameData.hero['homeLocationId'];
  if (homeLocationId != null) {
    final homeLocation = GameData.getLocation(homeLocationId);
    final homeSiteId = GameData.hero['homeSiteId'];

    final worldPosition = homeLocation['worldPosition'];
    engine.hetu.invoke('setTo', namespace: 'Player', positionalArgs: [
      worldPosition['left'],
      worldPosition['top'],
    ]);

    await engine.pushScene(
      homeLocationId,
      constructorId: Scenes.location,
      arguments: {'locationId': homeLocationId},
    );
    await engine.pushScene(
      homeSiteId,
      constructorId: Scenes.location,
      arguments: {
        'locationId': homeSiteId,
        'onEnterScene': () async {
          dialog.pushDialog(
            'hint_return_home_afterDying_${GameLogic.random.nextInt(_kHintDyingVariants) + 1}',
            isHero: true,
          );
          await dialog.execute();
        }
      },
    );
  }

  await Future.delayed(const Duration(milliseconds: 500));

  engine.setLoading(false);
  gameState.isInteractable = true;
}

void _heroRest(dynamic location) async {
  final siteKind = location['kind'];

  int developmentFactor = location['development'] + 1;
  int lifeRestorePerTime = kHomeLifeRestorePerTime;
  int restCostPerTime = 0;
  if (location['id'] != GameData.hero['homeSiteId']) {
    if (siteKind == 'cityhall') {
      if (location['sectId'] != GameData.hero['sectId']) {
        dialog.pushDialog(
          'hint_notYourHomeToRest',
          npcId: location['npcId'],
        );
        await dialog.execute();
        return;
      }
    } else if (siteKind == 'hotel') {
      dialog.pushDialog('hint_restAtHotel', npcId: location['npcId']);
      dialog.pushSelectionRaw(
        {
          'id': 'hotel_selection',
          'selections': {
            'hotelRoom_vip': {
              'text': engine.locale('hotelRoom_vip'),
              'description':
                  engine.locale('hotelRoom_description', interpolations: [
                kHotelVipCostPerTime * kTimesPerDay * developmentFactor,
                kHotelVipLifeRestorePerTime * kTimesPerDay * developmentFactor,
              ]),
            },
            'hotelRoom_normal': {
              'text': engine.locale('hotelRoom_normal'),
              'description':
                  engine.locale('hotelRoom_description', interpolations: [
                kHotelNormalCostPerTime * kTimesPerDay * developmentFactor,
                kHotelNormalLifeRestorePerTime *
                    kTimesPerDay *
                    developmentFactor,
              ]),
            },
            'hotelRoom_stable': {
              'text': engine.locale('hotelRoom_stable'),
              'description':
                  engine.locale('hotelRoom_description', interpolations: [
                kHotelStableCostPerTime * kTimesPerDay,
                kHomeLifeRestorePerTime * kTimesPerDay,
              ]),
            },
            'forgetIt': engine.locale('forgetIt'),
          },
        },
      );
      await dialog.execute();
      final selected = dialog.checkSelected('hotel_selection');
      if (selected == null || selected == 'forgetIt') {
        return;
      }
      switch (selected) {
        case 'hotelRoom_vip':
          restCostPerTime = kHotelVipCostPerTime * developmentFactor;
          lifeRestorePerTime = kHotelVipLifeRestorePerTime * developmentFactor;
        case 'hotelRoom_normal':
          restCostPerTime = kHotelNormalCostPerTime * developmentFactor;
          lifeRestorePerTime =
              kHotelNormalLifeRestorePerTime * developmentFactor;
        case 'hotelRoom_stable':
          restCostPerTime = kHotelStableCostPerTime;
          lifeRestorePerTime = kHomeLifeRestorePerTime;
      }
      dialog.pushDialog('hint_hotelRoom_selected', npcId: location['npcId']);
      await dialog.execute();
    } else {
      engine.error('非可休息场所: [${location['name']}] ($siteKind)');
      return;
    }
  }

  dialog.pushSelection('restOption', [
    'rest1Days',
    'rest5Days',
    'rest15Days',
    'restTillNextMonth',
    'restTillFullHealth',
    'restIndefinitely',
    'cancel',
  ]);
  await dialog.execute();
  final selected = dialog.checkSelected('restOption');
  bool stopAtFullHealth = false;
  int? ticks;
  switch (selected) {
    case 'rest1Days':
      ticks = kTicksPerDay;
    case 'rest5Days':
      ticks = kTicksPerDay * 5;
    case 'rest15Days':
      ticks = kTicksPerDay * 15;
    case 'restTillNextMonth':
      ticks = kTicksPerMonth - GameLogic.ticksOfMonth;
    case 'restTillFullHealth':
      final t =
          ((GameData.hero['stats']['lifeMax'] - GameData.hero['life'].round()) /
                      lifeRestorePerTime)
                  .ceil() *
              kTicksPerTime;
      if (t <= 0) {
        dialog.pushDialog('hint_alreadyFullHealthNoNeedRest');
        await dialog.execute();
        return;
      }
      stopAtFullHealth = true;
      ticks = t;
    case 'restIndefinitely':
      ticks = null;
    default:
      return;
  }

  await TimeflowDialog.show(
    context: engine.context,
    ticks: ticks,
    onProgress: () {
      engine.hetu.invoke('restoreLife',
          namespace: 'Player', positionalArgs: [lifeRestorePerTime]);
      gameState.updateUI();
      if (restCostPerTime > 0) {
        final haveMoney = GameData.hero['materials']['money'];
        if (haveMoney < restCostPerTime) {
          dialog.pushDialog('hint_notEnough_money');
          dialog.execute();
          return true;
        } else {
          engine.hetu.invoke('exhaust',
              namespace: 'Player', positionalArgs: ['money', restCostPerTime]);
        }
      }

      if (stopAtFullHealth) {
        return GameData.hero['life'] >= GameData.hero['stats']['lifeMax'];
      }

      return false;
    },
  );

  engine.hetu.invoke('onGameEvent', positionalArgs: ['onRested']);
}

Future<void> _heroDivination(dynamic location) async {
  // 介绍占卜功能
  dialog.pushDialog('hint_divination_intro', npcId: location['npcId']);
  await dialog.execute();

  // 选择占卜类型
  dialog.pushSelection('divination_type', [
    'divination_self',
    'divination_other',
    'cancel',
  ]);
  await dialog.execute();
  final selected = dialog.checkSelected('divination_type');

  switch (selected) {
    case 'divination_self':
      // 选择具体占卜内容
      dialog.pushSelection('divination_self_topic', [
        'divination_self_luck',
        'divination_self_wisdom',
        'divination_self_lifespan',
        'cancel',
      ]);
      await dialog.execute();
      final topic = dialog.checkSelected('divination_self_topic');
      if (topic == 'cancel') return;

      final int rank = GameData.hero['rank'];
      final int cost = kDivinationSelfBaseCost * (rank + 1);

      // 确认费用
      dialog.pushDialog('hint_divination_cost',
          npcId: location['npcId'], interpolations: [cost]);
      dialog.pushSelection('divination_confirm_selection', [
        'divination_confirm',
        'cancel',
      ]);
      await dialog.execute();
      final confirm = dialog.checkSelected('divination_confirm_selection');
      if (confirm != 'divination_confirm') return;

      // 检查灵石
      final int haveShard = GameData.hero['materials']['shard'];
      if (haveShard < cost) {
        dialog.pushDialog('hint_divination_not_enough_shard',
            npcId: location['npcId']);
        await dialog.execute();
        return;
      }

      // 扣除灵石
      engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
        'shard',
        cost,
      ]);

      switch (topic) {
        case 'divination_self_luck':
          final int luck = GameData.hero['stats']['luck'] ?? 0;
          final luckDesc = engine.locale(
              'divination_level_${_getDivinationLevel(luck, kDivinationThresholds)}');
          dialog.pushDialog('hint_divination_self_luck_result',
              npcId: location['npcId'], interpolations: [luckDesc]);
          await dialog.execute();

        case 'divination_self_wisdom':
          final int wisdom = GameData.hero['stats']['wisdom'] ?? 0;
          final wisdomDesc = engine.locale(
              'divination_level_${_getDivinationLevel(wisdom, kDivinationThresholds)}');
          dialog.pushDialog('hint_divination_self_wisdom_result',
              npcId: location['npcId'], interpolations: [wisdomDesc]);
          await dialog.execute();

        case 'divination_self_lifespan':
          final lifespanData = GameLogic.getLifeSpanForRank(rank);
          final int expectedLifespanTicks =
              ((lifespanData['min']! + lifespanData['max']!) /
                      2 *
                      kTicksPerYear)
                  .round();
          final int restLifespanTicks = GameData.hero['deathTimestamp'] -
              GameData.game['timestamp'] as int;
          final double lifespanRatio = expectedLifespanTicks > 0
              ? restLifespanTicks / expectedLifespanTicks
              : 0;
          final lifespanDesc = engine.locale(
              'divination_lifespan_${_getDivinationLevelByRatio(lifespanRatio, kDivinationLifespanThresholds)}');
          dialog.pushDialog('hint_divination_self_lifespan_result',
              npcId: location['npcId'], interpolations: [lifespanDesc]);
          await dialog.execute();
      }

    case 'divination_other':
      // 从已遇到的角色中选择
      final bonds = GameData.hero['bonds'];
      assert(bonds != null);
      final bondIds = bonds.keys.where((id) => id != GameData.hero['id']);
      if (bondIds.isEmpty) {
        dialog.pushDialog('hint_divination_no_bonds', npcId: location['npcId']);
        await dialog.execute();
        return;
      }

      final targetId = await GameLogic.selectCharacter(ids: bondIds);
      if (targetId == null) return;

      // 选择具体占卜内容
      dialog.pushSelection('divination_other_topic', [
        'divination_other_charisma',
        'divination_other_cultivation',
        'divination_other_sect',
        'divination_other_location',
        'cancel',
      ]);
      await dialog.execute();
      final topic = dialog.checkSelected('divination_other_topic');
      if (topic == 'cancel') return;

      final target = GameData.getCharacter(targetId);
      final int targetRank = target['rank'];
      final int cost = kDivinationOtherBaseCost * (targetRank + 1);

      // 确认费用
      dialog.pushDialog('hint_divination_cost',
          npcId: location['npcId'], interpolations: [cost]);
      dialog.pushSelection('divination_confirm_selection', [
        'divination_confirm',
        'cancel',
      ]);
      await dialog.execute();
      final confirm = dialog.checkSelected('divination_confirm_selection');
      if (confirm != 'divination_confirm') return;

      // 检查灵石
      final int haveShard = GameData.hero['materials']['shard'];
      if (haveShard < cost) {
        dialog.pushDialog('hint_divination_not_enough_shard',
            npcId: location['npcId']);
        await dialog.execute();
        return;
      }

      // 扣除灵石
      engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
        'shard',
        cost,
      ]);

      switch (topic) {
        case 'divination_other_charisma':
          final int charismaFavor = target['charismaFavor'] ?? 50;
          final int heroCharisma = GameData.hero['stats']['charisma'] ?? 50;
          final int charismaDiff = (charismaFavor - heroCharisma).abs();
          final charismaDesc = engine.locale(
              'divination_charisma_favor_${_getDivinationCharismaFavorLevel(charismaDiff, kDivinationCharismaFavorThresholds)}');
          dialog.pushDialog('hint_divination_other_charisma_result',
              npcId: location['npcId'], interpolations: [charismaDesc]);
          await dialog.execute();

        case 'divination_other_cultivation':
          final String cultivationFavor =
              target['cultivationFavor'] ?? 'swordcraft';
          final cultivationDesc = engine.locale(cultivationFavor);
          dialog.pushDialog('hint_divination_other_cultivation_result',
              npcId: location['npcId'], interpolations: [cultivationDesc]);
          await dialog.execute();

        case 'divination_other_sect':
          final String sectFavor = target['sectFavor'] ?? 'wuwei';
          final sectDesc = engine.locale(sectFavor);
          dialog.pushDialog('hint_divination_other_sect_result',
              npcId: location['npcId'], interpolations: [sectDesc]);
          await dialog.execute();

        case 'divination_other_location':
          final String? targetLocationId = target['locationId'];
          final targetWorldPos = target['worldPosition'];

          if (targetLocationId != null) {
            // 角色在某个具体场景中
            final targetLocation = GameData.getLocation(targetLocationId);
            final String locName = targetLocation['name'];
            final String? atCityId = targetLocation['atCityId'];
            if (atCityId != null) {
              // 子场景，获取所在城市名字和城市坐标
              final city = GameData.getLocation(atCityId);
              final cityWorldPos = city['worldPosition'];
              if (cityWorldPos != null) {
                dialog.pushDialog('hint_divination_other_location_site_result',
                    npcId: location['npcId'],
                    interpolations: [
                      city['name'],
                      locName,
                      cityWorldPos['left'],
                      cityWorldPos['top'],
                    ]);
              } else {
                dialog.pushDialog(
                    'hint_divination_other_location_site_nopos_result',
                    npcId: location['npcId'],
                    interpolations: [city['name'], locName]);
              }
            } else {
              // 城市或大地图上的独立场景（如生产建筑）
              final locWorldPos = targetLocation['worldPosition'];
              if (locWorldPos != null) {
                dialog.pushDialog('hint_divination_other_location_city_result',
                    npcId: location['npcId'],
                    interpolations: [
                      locName,
                      locWorldPos['left'],
                      locWorldPos['top'],
                    ]);
              } else {
                dialog.pushDialog(
                    'hint_divination_other_location_city_nopos_result',
                    npcId: location['npcId'],
                    interpolations: [locName]);
              }
            }
            await dialog.execute();
          } else if (targetWorldPos != null) {
            // 角色在大地图上
            final int left = targetWorldPos['left'];
            final int top = targetWorldPos['top'];
            dialog.pushDialog('hint_divination_other_location_world_result',
                npcId: location['npcId'], interpolations: [left, top]);
            await dialog.execute();
          } else {
            // 没有任何位置信息，占卜失败
            dialog.pushDialog('hint_divination_other_location_failed',
                npcId: location['npcId']);
            await dialog.execute();
          }
      }
  }
}

/// 根据属性数值和阈值列表返回1~5的档位
int _getDivinationLevel(int value, List<int> thresholds) {
  for (int i = 0; i < thresholds.length; i++) {
    if (value < thresholds[i]) return i + 1;
  }
  return 5;
}

/// 根据比例值和阈值列表返回1~5的档位
int _getDivinationLevelByRatio(double ratio, List<double> thresholds) {
  for (int i = 0; i < thresholds.length; i++) {
    if (ratio < thresholds[i]) return i + 1;
  }
  return 5;
}

/// 根据魅力偏好差值返回1~5的档位（差值越小档位越高）
int _getDivinationCharismaFavorLevel(int diff, List<int> thresholds) {
  for (int i = thresholds.length - 1; i >= 0; i--) {
    if (diff >= thresholds[i]) return i + 1;
  }
  return 5;
}

Future<void> _heroProduce(dynamic location) async {
  final siteKind = location['kind'];
  assert(
      kProductionSiteKinds.contains(siteKind) &&
          kSiteWorkableStaminaCost.containsKey(siteKind),
      '非可生产场所: ${location['name']} ($siteKind)');

  final isRented = await GameLogic.checkRented(location);
  if (!isRented) return;

  if (GameData.hero['life'] <= 1) {
    dialog.pushDialog(
      'hint_notEnoughStaminaToWork',
      npcId: location['npcId'],
    );
    await dialog.execute();
    return;
  }

  engine.pushScene(
    Scenes.matchingGame,
    arguments: {
      'kind': siteKind,
      'location': location,
      'isProduction': true,
    },
  );
}

Future<void> _heroWork(dynamic location) async {
  final siteKind = location['kind'];
  if (!kSiteKindsWorkable.contains(siteKind)) {
    engine.error('非可工作场所: ${location['name']} ($siteKind)');
    return;
  }

  // 非门派成员，只能在一年中的指定时间打工
  // 门派成员则不受时间限制
  if (location['sectId'] != null &&
      location['sectId'] != GameData.hero['sectId']) {
    final months = kSiteWorkableMounths[siteKind] as List;
    if (!months.contains(GameLogic.month)) {
      dialog.pushDialog(
        'hint_notWorkSeason',
        npcId: location['npcId'],
        interpolations: [months.join(', ')],
      );
      await dialog.execute();
      return;
    }
  }

  if (GameData.hero['life'] <= 1) {
    dialog.pushDialog(
      'hint_notEnoughStaminaToWork',
      npcId: location['npcId'],
    );
    await dialog.execute();
    return;
  }

  engine.pushScene(
    Scenes.matchingGame,
    arguments: {
      'kind': siteKind,
      'location': location,
      'isProduction': false,
    },
  );
}

/// 玩家尝试加入门派（入门试炼）
/// [sect] 门派对象，[npc] 负责招募的NPC对象
Future<void> _heroEnrollSect(dynamic sect, dynamic npc) async {
  // 检查玩家境界是否达到最低要求
  final int heroRank = GameData.hero['rank'];
  if (heroRank < kSectEnrollMinRank) {
    final heroRankString =
        '<rank$heroRank>${engine.locale('cultivationRank_$heroRank')}</>';
    final requiredRankString =
        '<rank$kSectEnrollMinRank>${engine.locale('cultivationRank_$kSectEnrollMinRank')}</>';
    dialog.pushDialog(
      'hint_enroll_rankTooLow',
      npc: npc,
      interpolations: [heroRankString, requiredRankString],
    );
    await dialog.execute();
    return;
  }

  // 检查门派招募月份
  final recruitMonth = sect['recruitMonth'];
  if (recruitMonth != GameLogic.month) {
    dialog.pushDialog(
      'hint_notRecruitMonth',
      interpolations: [recruitMonth],
      npc: npc,
    );
    await dialog.execute();
    return;
  }
  // 玩家本月是否已经进行过此门派的试炼
  if (GameData.checkMonthly(MonthlyActivityIds.enrolled, sect['id'])) {
    dialog.pushDialog(
      'hint_alreadyTrialedThisMonth',
      npc: npc,
    );
    return;
  }
  final sectCategory = sect['category'];
  assert(kSectCategories.contains(sectCategory));
  dialog.pushDialog(
    'sect_${sectCategory}_trial_intro',
    npc: npc,
  );
  await dialog.execute();
  switch (sectCategory) {
    case 'wuwei':
      bool passed = true;
      final questions =
          List<int>.generate(kWuweiTrialQuestionCount, (i) => i + 1);
      questions.shuffle();
      final selectedQuestions = questions.skip(5);
      for (final q in selectedQuestions) {
        final qString = 'sect_wuwei_trial_question_$q';
        dialog.pushDialog(
          qString,
          npc: npc,
        );
        await dialog.execute();
        final trialQuestionAnswers = [];
        for (var i = 0; i < kWuweiTrialOptionsCount; ++i) {
          trialQuestionAnswers.add('${qString}_option_${i + 1}');
        }
        dialog.pushSelection(qString, trialQuestionAnswers);
        await dialog.execute();
        final selectedAnswer = dialog.checkSelected(qString);
        dialog.pushDialog(
          '${selectedAnswer}_comment',
          npc: npc,
        );
        await dialog.execute();
        final correctAnswer = kWuweiTrialAnswers[q];
        if (selectedAnswer != '${qString}_option_$correctAnswer') {
          passed = false;
          break;
        }
      }
      if (passed) {
        dialog.pushDialog(
          'sect_${sectCategory}_trial_pass',
          npc: npc,
        );
        await dialog.execute();
        await engine.hetu.invoke(
          'enroll',
          namespace: 'Player',
          positionalArgs: [sect],
          namedArgs: {
            'npcId': npc['id'],
          },
        );
      } else {
        GameData.addMonthly(MonthlyActivityIds.enrolled, sect['id']);
        dialog.pushDialog(
          'sect_${sectCategory}_trial_fail',
          npc: npc,
        );
        await dialog.execute();
      }
    case 'cultivation':
      final enemy = engine.hetu.invoke('Character', namedArgs: {
        'name': 'wooden_dummy',
        'isFemale': false,
        'level': 10,
        'rank': 0,
        'icon': 'illustration/npc/wooden_dummy_head.png',
        'skin': 'wooden_dummy',
        'attributes': {
          'charisma': 0,
          'wisdom': 0,
          'luck': 0,
          'spirituality': 0,
          'dexterity': 0,
          'strength': 120,
          'willpower': 0,
          'perception': 0,
        },
        'cultivationFavor': '',
        'allocateSkills': false,
        'autoGenerateDeck': false,
      });
      engine.hetu.invoke('generateBattleDeck', positionalArgs: [
        enemy
      ], namedArgs: {
        'cardInfoList': [
          {
            'affixId': 'blank_default',
          },
          {
            'affixId': 'blank_default',
          },
          {
            'affixId': 'blank_default',
          },
        ],
      });
      engine.context.read<EnemyState>().show(
        enemy,
        loseOnEscape: true,
        onBattleEnd: (bool battleResult, int roundCount) async {
          if (roundCount <= kCultivationTrialMinBattleRound) {
            dialog.pushDialog(
              'sect_${sectCategory}_trial_pass',
              npc: npc,
            );
            await dialog.execute();
            await engine.hetu.invoke(
              'enroll',
              namespace: 'Player',
              positionalArgs: [sect],
              namedArgs: {
                'npcId': npc['id'],
              },
            );
          } else {
            GameData.addMonthly(MonthlyActivityIds.enrolled, sect['id']);
            dialog.pushDialog(
              'sect_${sectCategory}_trial_fail',
              npc: npc,
            );
            await dialog.execute();
          }
        },
      );
    case 'immortality':
      engine.hetu.invoke('resetTrial', namedArgs: {
        'name': engine.locale('cultivation_trial'),
        'difficulty': 0,
        'sectId': sect['id'],
        'npcId': npc['id'],
      });
      engine.pushScene(
        'cultivation_trial_1',
        constructorId: Scenes.worldmap,
        arguments: {
          'id': 'cultivation_trial_1',
          'method': 'load',
        },
      );
    case 'chivalry':
      final enemy = engine.hetu.invoke('BattleEntity', namedArgs: {
        'rank': GameData.hero['rank'],
        'name': engine.locale('trialCompetitor'),
      });
      engine.context.read<EnemyState>().show(
        enemy,
        loseOnEscape: true,
        onBattleEnd: (bool battleResult, int roundCount) async {
          if (battleResult) {
            dialog.pushDialog(
              'sect_${sectCategory}_trial_pass',
              npc: npc,
            );
            await dialog.execute();
            await engine.hetu.invoke(
              'enroll',
              namespace: 'Player',
              positionalArgs: [sect],
              namedArgs: {
                'npcId': npc['id'],
              },
            );
          } else {
            GameData.addMonthly(MonthlyActivityIds.enrolled, sect['id']);
            dialog.pushDialog(
              'sect_${sectCategory}_trial_fail',
              npc: npc,
            );
            await dialog.execute();
          }
        },
      );
    case 'entrepreneur':
      final Iterable membersData = sect['membersData'].values;
      final testersData = membersData.where((m) {
        return m['rank'] == GameData.hero['rank'];
      }).toList();
      dynamic tester;
      if (testersData.isNotEmpty) {
        testersData.sort((a, b) => a['rank'].compareTo(b['rank']));
        tester = GameData.getCharacter(testersData.first['id']);
      } else {
        tester = engine.hetu.invoke('BattleEntity', namedArgs: {
          'rank': GameData.hero['rank'],
          'name': engine.locale('trialTester'),
        });
      }
      engine.context.read<EnemyState>().show(
        tester,
        loseOnEscape: true,
        onBattleEnd: (bool battleResult, int roundCount) async {
          if (battleResult) {
            dialog.pushDialog(
              'sect_${sectCategory}_trial_pass',
              npc: npc,
            );
            await dialog.execute();
            await engine.hetu.invoke(
              'enroll',
              namespace: 'Player',
              positionalArgs: [sect],
              namedArgs: {
                'npcId': npc['id'],
              },
            );
          } else {
            GameData.addMonthly(MonthlyActivityIds.enrolled, sect['id']);
            dialog.pushDialog(
              'sect_${sectCategory}_trial_fail',
              npc: npc,
            );
            await dialog.execute();
          }
        },
      );
    case 'wealth':
      final int cost = kWealthTrialCost;
      dialog.pushSelectionRaw({
        'id': 'sect_wealth_trial',
        'selections': {
          'pay_shard': engine.locale('pay_shard', interpolations: [cost]),
          'forgetIt': engine.locale('forgetIt'),
        }
      });
      await dialog.execute();
      final selected = dialog.checkSelected('sect_wealth_trial');
      if (selected == 'pay_shard') {
        final int shard = GameData.hero['materials']['shard'] ?? 0;
        if (shard >= cost) {
          engine.hetu.invoke(
            'exhaust',
            namespace: 'Player',
            positionalArgs: ['shard', cost],
          );
          dialog.pushDialog(
            'sect_${sectCategory}_trial_pass',
            npc: npc,
          );
          await dialog.execute();
          await engine.hetu.invoke(
            'enroll',
            namespace: 'Player',
            positionalArgs: [sect],
            namedArgs: {
              'npcId': npc['id'],
            },
          );
        } else {
          dialog.pushDialog(engine.locale('hint_notEnoughShard'));
          dialog.pushDialog(
            'sect_${sectCategory}_trial_fail',
            npc: npc,
          );
          await dialog.execute();
        }
      }
    case 'pleasure':
      final heroCharisma = GameData.hero['stats']['charisma'];
      if (heroCharisma >= kPleasureTrialMinCharisma) {
        dialog.pushDialog(
          'sect_${sectCategory}_trial_pass',
          npc: npc,
        );
        await dialog.execute();
        await engine.hetu.invoke(
          'enroll',
          namespace: 'Player',
          positionalArgs: [sect],
          namedArgs: {
            'npcId': npc['id'],
          },
        );
      } else {
        dialog.pushDialog(
          'sect_${sectCategory}_trial_fail',
          npc: npc,
        );
        await dialog.execute();
      }
  }
}

Future<void> _onInteractNpc(dynamic location) async {
  final npc = GameData.game['npcs'][location['npcId']];
  assert(npc != null);
  engine.info('正在和 NPC [${npc['name']}] 互动。');
  if (npc['useCustomLogic'] == true) {
    engine.info('NPC [${npc.id}] 使用自定义逻辑。');
    engine.hetu
        .invoke('onGameEvent', positionalArgs: ['onInteractNpc', location]);
    return;
  }

  /// 这里的 sect 可能是 null
  final sect = GameData.game['sects'][location['sectId']];

  /// 这里的 atCity 可能是 null
  final atCity = GameData.game['locations'][location['atCityId']];

  final heroId = GameData.hero['id'];

  bool isManager = heroId == location['managerId'];
  bool isMayor = heroId == atCity?['managerId'];
  bool isHead = heroId == sect?['headId'];

  bool isAdmin = isManager || isMayor || isHead;

  final siteKind = location['kind'];
  if (siteKind == 'headquarters') {
    await _onInteractHeadquarters(location, npc, sect, isAdmin, heroId);
  } else if (siteKind == 'cityhall') {
    await _onInteractCityhall(location, npc, sect, atCity, isAdmin, heroId);
  } else {
    await _onInteractSite(location, siteKind, isAdmin);
  }
}

Future<void> _onInteractHeadquarters(
  dynamic location,
  dynamic npc,
  dynamic sect,
  bool isAdmin,
  dynamic heroId,
) async {
  final siteKind = location['kind'];
  final siteOptions = ['sectInformation'];
  final heroSectId = GameData.hero['sectId'];
  if (heroSectId == null) {
    siteOptions.add('enroll');
  } else {
    if (heroSectId == sect['id']) {
      if (heroId != sect['headId']) {
        siteOptions.add('resign');
      }
    } else {
      final heroTitleId = GameData.hero['titleId'];
      if (heroTitleId == 'head' || heroTitleId == 'envoy') {
        final heroSect = GameData.getSect(heroSectId);
        var diplomacyDataId = sect['diplomacies'][heroSectId];
        if (diplomacyDataId == null) {
          final result = engine.hetu.invoke(
            'updateDiplomacy',
            positionalArgs: [heroSect, sect],
            namedArgs: {
              'type': 'neutral',
              'score': kDiplomacyDefaultScore,
            },
          );
          diplomacyDataId = result['id'];
        }
        final diplomacyData = GameData.game['diplomacies'][diplomacyDataId];
        assert(diplomacyData != null);
        final String type = diplomacyData['type'];
        final score = diplomacyData['score'] as int;
        siteOptions.add('sectDiplomacy');
        switch (type) {
          case 'ally':
            siteOptions.add('breakAlliance');
          case 'pact':
            siteOptions.add('breakPact');
            if (score >= kDiplomacyScoreAllyThreshold) {
              siteOptions.add('formAlliance');
            }
            siteOptions.add('makeFriend');
          case 'enemy':
            siteOptions.add('startPeaceTalk');
          case 'truce':
            siteOptions.add('makeFriend');
          case 'neutral':
            if (score >= kDiplomacyScoreAllyThreshold) {
              siteOptions.add('formAlliance');
            }
            if (score >= kDiplomacyScorePactThreshold) {
              siteOptions.add('signPact');
            }
            if (score <= kDiplomacyScoreEnemyThreshold) {
              siteOptions.add('declareWar');
            }
            siteOptions.add('makeFriend');
        }
      }
    }
  }
  if (heroId != sect['headId']) {
    siteOptions.add('donate');
  }
  siteOptions.add('checkSectContribution');
  siteOptions.add('cancel');
  dialog.pushSelection(siteKind, siteOptions);
  await dialog.execute();
  final selected = dialog.checkSelected(siteKind);
  switch (selected) {
    case 'sectInformation':
      engine.context.read<ViewPanelState>().toogle(
        ViewPanels.sectInformation,
        arguments: {
          'sect': sect,
          'isAdmin': isAdmin,
        },
      );
    case 'enroll':
      await _heroEnrollSect(sect, npc);
    case 'resign':
      final memberData = sect['membersData'][heroId];
      final jobRank = memberData['rank'] ?? 0;
      if (jobRank >= 3) {
        dialog.pushDialog('sect_resign_1', npc: npc);
        await dialog.execute();
        final resignSelections = [
          'resign_confirm',
          'forgetIt',
        ];
        dialog.pushSelection('resign_selections', resignSelections);
        final selected = dialog.checkSelected('resign_selections');
        if (selected != 'resign_confirm') return;
      }
      dialog.pushDialog('sect_resign_confirm', interpolations: [sect['name']]);
      await dialog.execute();
      engine.hetu.invoke(
        'removeCharacterFromSect',
        positionalArgs: [GameData.hero, sect],
      );
      dialog.pushDialog('hint_sect_resign', interpolations: [sect['name']]);
      await dialog.execute();
    case 'donate':
      final alreadyDonated = GameData.checkMonthly('donated', sect['id']);
      if (alreadyDonated) {
        dialog.pushDialog('hint_already_donated',
            npc: npc, interpolations: [_kGameFlagsUpdateDay]);
        await dialog.execute();
        return;
      }
      dialog.pushDialog([
        'hint_sect_donation',
        'hint_donation',
      ], npc: npc);
      await dialog.execute();
      final items = await GameLogic.selectItem(
          character: GameData.hero, multiSelect: false);
      final item = items.firstOrNull;
      if (item == null) return;
      final int itemPrice = item['price'] ?? 0;
      int contribution = (itemPrice * kItemPriceToContributionRate).floor();
      if (contribution < 1) {
        dialog.pushDialog('hint_donation_item_value_low', npc: npc);
        await dialog.execute();
      } else {
        dialog.pushDialog('hint_donation_item_value_high',
            npc: npc, interpolations: [contribution]);
        await dialog.execute();
        final contributionData = {
          'stackSize': contribution,
          'sectId': sect['id'],
        };
        engine.hetu.invoke('characterMakeContribution',
            positionalArgs: [GameData.hero, contributionData]);
      }
    case 'checkSectContribution':
      final memberData = sect['membersData'][heroId];
      int contribution = 0;
      if (memberData != null) {
        contribution = memberData['contribution'] ?? 0;
      }
      dialog.pushDialog('hint_checkSectContribution',
          npc: npc, interpolations: [contribution]);
      await dialog.execute();
    case 'sectDiplomacy':
    case 'formAlliance':
    case 'breakAlliance':
    case 'signPact':
    case 'breakPact':
    case 'declareWar':
    case 'startPeaceTalk':
    case 'makeFriend':
      await _handleDiplomacyAction(selected!, npc, sect);
  }
}

Future<void> _handleDiplomacyAction(
  String action,
  dynamic npc,
  dynamic sect,
) async {
  final heroSectId = GameData.hero['sectId'];
  final heroSect = GameData.getSect(heroSectId);
  switch (action) {
    case 'sectDiplomacy':
      final diplomacyDataId = sect['diplomacies'][heroSectId];
      final diplomacyData = GameData.game['diplomacies'][diplomacyDataId];
      final typeLocale = engine.locale('diplomacy_${diplomacyData['type']}');
      dialog.pushDialog(
        'hint_sect_diplomacy_current',
        npc: npc,
        interpolations: [
          heroSect['name'],
          sect['name'],
          typeLocale,
          diplomacyData['score'],
        ],
      );
      await dialog.execute();
    case 'formAlliance':
      engine.hetu.invoke(
        'updateDiplomacy',
        positionalArgs: [heroSect, sect],
        namedArgs: {'type': 'ally'},
      );
      dialog.pushDialog(
        'hint_sect_diplomacy_form_alliance',
        npc: npc,
        interpolations: [sect['name'], heroSect['name']],
      );
      await dialog.execute();
    case 'breakAlliance':
      engine.hetu.invoke(
        'updateDiplomacy',
        positionalArgs: [heroSect, sect],
        namedArgs: {'type': 'neutral'},
      );
      dialog.pushDialog(
        'hint_sect_diplomacy_break_alliance',
        npc: npc,
        interpolations: [heroSect['name'], sect['name']],
      );
      await dialog.execute();
    case 'signPact':
      engine.hetu.invoke(
        'updateDiplomacy',
        positionalArgs: [heroSect, sect],
        namedArgs: {'type': 'pact'},
      );
      dialog.pushDialog(
        'hint_sect_diplomacy_sign_pact',
        npc: npc,
        interpolations: [heroSect['name'], sect['name']],
      );
      await dialog.execute();
    case 'breakPact':
      engine.hetu.invoke(
        'updateDiplomacy',
        positionalArgs: [heroSect, sect],
        namedArgs: {'type': 'neutral'},
      );
      dialog.pushDialog(
        'hint_sect_diplomacy_break_pact',
        npc: npc,
        interpolations: [heroSect['name'], sect['name']],
      );
      await dialog.execute();
    case 'declareWar':
      // 宣战: 更新关系为 enemy，扣除 score
      engine.hetu.invoke(
        'updateDiplomacy',
        positionalArgs: [heroSect, sect],
        namedArgs: {'type': 'enemy'},
      );
      engine.hetu.invoke(
        'updateDiplomacyScore',
        positionalArgs: [heroSect, sect, kDiplomacyScoreWarDeclare],
      );
      // 盟友 C 对 A（宣战方）降低 score
      final allySectIds = sect['allySectIds'] as Iterable;
      for (final allySectId in allySectIds) {
        final allySect = GameData.getSect(allySectId);
        if (allySect != null) {
          final allyDiplomacy = allySect['diplomacies'][heroSect['id']];
          if (allyDiplomacy != null) {
            engine.hetu.invoke(
              'updateDiplomacyScore',
              positionalArgs: [allySect, heroSect, kDiplomacyScoreWarBystander],
            );
          }
        }
      }
      dialog.pushDialog(
        'hint_sect_diplomacy_declare_war',
        npc: npc,
        interpolations: [heroSect['name'], sect['name']],
      );
      await dialog.execute();
    case 'startPeaceTalk':
      // 停战持续 6 个月
      engine.hetu.invoke(
        'updateDiplomacy',
        positionalArgs: [heroSect, sect],
        namedArgs: {'type': 'truce', 'timespanByMonth': 6},
      );
      dialog.pushDialog(
        'hint_sect_diplomacy_start_peace_talk',
        npc: npc,
        interpolations: [heroSect['name'], sect['name']],
      );
      await dialog.execute();
    case 'makeFriend':
      // 增进关系，赠礼（消耗少量铜钱）
      const giftCost = 1000;
      final exhausted = engine.hetu.invoke(
        'exhaust',
        namespace: 'Player',
        positionalArgs: ['money', giftCost],
      ) as int;
      if (exhausted >= giftCost) {
        final scoreDelta = (giftCost / 10).floor();
        engine.hetu.invoke(
          'updateDiplomacyScore',
          positionalArgs: [heroSect, sect, scoreDelta],
        );
        dialog.pushDialog(
          'hint_sect_diplomacy_make_friend',
          npc: npc,
          interpolations: [heroSect['name'], sect['name']],
        );
      } else {
        dialog.pushDialog(
          'hint_notEnough',
          npc: npc,
          interpolations: [engine.locale('money')],
        );
      }
      await dialog.execute();
  }
}

Future<void> _onInteractCityhall(
  dynamic location,
  dynamic npc,
  dynamic sect,
  dynamic atCity,
  bool isAdmin,
  dynamic heroId,
) async {
  final siteKind = location['kind'];
  final heroRank = GameData.hero['rank'];
  final siteOptions = <dynamic>[];
  if (sect != null) {
    siteOptions.add('sectInformation');
  }
  siteOptions.add('cityInformation');
  siteOptions.add('bountyQuest');
  if (sect == null) {
    if (GameData.hero['sectId'] == null) {
      siteOptions.add('createSect2');
    } else {
      if (GameData.hero['titleId'] == 'head') {
        siteOptions.add('recruitCity');
      }
    }
    siteOptions.add('donate');
    siteOptions.add('checkCityContribution');
  } else {
    siteOptions.add('checkSectContribution');
  }
  if (((sect == null && GameData.hero['sectId'] == null) ||
          (sect != null && sect['id'] == GameData.hero['sectId'])) &&
      GameData.hero['homeLocationId'] != atCity['id']) {
    siteOptions.add('moveHere');
  }
  siteOptions.add('cancel');

  dialog.pushSelection(siteKind, siteOptions);
  await dialog.execute();
  final selected = dialog.checkSelected(siteKind);
  switch (selected) {
    case 'sectInformation':
      engine.context.read<ViewPanelState>().toogle(
        ViewPanels.sectInformation,
        arguments: {
          'sect': sect,
          'isAdmin': isAdmin,
        },
      );
    case 'cityInformation':
      assert(atCity != null,
          '试图查看 cityInformation 但 atCity 为空, id: ${location['atCityId']}');
      engine.context.read<ViewPanelState>().toogle(
        ViewPanels.cityInformation,
        arguments: {
          'city': atCity,
          'isAdmin': isAdmin,
        },
      );
    case 'bountyQuest':
      final bounties = location['bounties'] ?? const [];
      if (bounties.isEmpty) {
        dialog.pushDialog(
          'hint_noAvailableQuests',
          name: npc['name'],
          icon: npc['icon'],
          image: npc['illustration'],
        );
        await dialog.execute();
        return;
      }
      final quest = await showDialog(
        context: engine.context,
        builder: (context) => BountyQuestListView(
          quests: bounties,
        ),
      );
      if (quest != null) {
        GameLogic.heroAcquireQuest(quest, location, sect);
      }
    case 'donate':
      final alreadyDonated = GameData.checkMonthly('donated', location['id']);
      if (alreadyDonated) {
        dialog.pushDialog('hint_already_donated',
            npc: npc, interpolations: [_kGameFlagsUpdateDay]);
        await dialog.execute();
        return;
      }
      dialog.pushDialog([
        'hint_location_donation',
        'hint_donation',
      ], npc: npc);
      await dialog.execute();
      final items = await GameLogic.selectItem(
          character: GameData.hero, multiSelect: false);
      final item = items.firstOrNull;
      if (item == null) return;
      final int itemPrice = item['price'] ?? 0;
      int contribution = (itemPrice * kItemPriceToContributionRate).floor();
      if (contribution < 1) {
        dialog.pushDialog('hint_donation_item_value_low', npc: npc);
        await dialog.execute();
      } else {
        dialog.pushDialog('hint_donation_item_value_high',
            npc: npc, interpolations: [contribution]);
        await dialog.execute();
        final contributionData = {
          'stackSize': contribution,
          'locationId': location['id'],
        };
        engine.hetu.invoke('characterMakeContribution',
            positionalArgs: [GameData.hero, contributionData]);
      }
    case 'checkCityContribution':
      final contribution = location['contributions'][GameData.hero['id']] ?? 0;
      dialog.pushDialog('hint_checkCityContribution',
          npc: npc, interpolations: [contribution]);
      await dialog.execute();
    case 'checkSectContribution':
      final memberData = sect['membersData'][heroId];
      int contribution = 0;
      if (memberData != null) {
        contribution = memberData['contribution'] ?? 0;
      }
      dialog.pushDialog('hint_checkSectContribution',
          npc: npc, interpolations: [contribution]);
      await dialog.execute();
    case 'moveHere':
      await _cityhallMoveHere(npc, atCity);
    case 'createSect2':
      await _cityhallCreateSect(npc, atCity, heroRank);
    case 'recruitCity':
      await _cityhallRecruitCity(location, npc, sect, atCity, heroId);
  }
}

Future<void> _cityhallCreateSect(
  dynamic npc,
  dynamic atCity,
  int heroRank,
) async {
  final rankString =
      '<rank$kCreateSectRequirementRank>${engine.locale('cultivationRank_$kCreateSectRequirementRank')}</>';
  dialog.pushDialog('hint_createSect_intro', npc: npc, interpolations: [
    rankString,
    kCreateSectRequirementMoney,
    kCreateSectRequirementShard,
  ]);
  await dialog.execute();
  final orgOrgId = GameData.hero['sectId'];
  if (orgOrgId != null) {
    final oldOrg = GameData.getSect(orgOrgId);
    dialog.pushDialog('hint_createSect_intro',
        npc: npc, interpolations: [oldOrg['name']]);
    await dialog.execute();
    return;
  }
  if (heroRank < kCreateSectRequirementRank) {
    final heroRankString =
        '<rank$heroRank>${engine.locale('cultivationRank_$heroRank')}</>';
    dialog.pushDialog('hint_createSect_rankTooLow', npc: npc, interpolations: [
      heroRankString,
      rankString,
    ]);
    await dialog.execute();
    return;
  }
  final hasMoney = GameData.hero['materials']['money'];
  final hasShard = GameData.hero['materials']['shard'];
  if (hasMoney < kCreateSectRequirementMoney ||
      hasShard < kCreateSectRequirementShard) {
    dialog.pushDialog('hint_createSect_notEnoughMoneyOrShard',
        npc: npc,
        interpolations: [
          kCreateSectRequirementMoney,
          kCreateSectRequirementShard,
        ]);
    await dialog.execute();
    return;
  }
  engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
    'money',
    kCreateSectRequirementMoney,
  ]);
  engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
    'shard',
    kCreateSectRequirementShard,
  ]);
  String? name;
  while (name == null) {
    dialog.pushDialog('hint_createSect_success_1', npc: npc);
    await dialog.execute();
    name = await showDialog(
      context: engine.context,
      builder: (context) => InputNameDialog(
        mode: InputNameMode.sect,
      ),
    );
  }
  String? category;
  while (category == null) {
    dialog.pushDialog('hint_createSect_success_2',
        npc: npc, interpolations: [name]);
    await dialog.execute();
    category = await GameLogic.selectFrom(kSectCategories);
  }
  String? genre;
  while (genre == null) {
    dialog.pushDialog('hint_createSect_success_3',
        npc: npc, interpolations: [category, name]);
    await dialog.execute();
    genre = await GameLogic.selectFrom(kCultivationGenres);
  }
  dialog.pushDialog('hint_createSect_success_4',
      npc: npc, interpolations: [genre, name]);
  await dialog.execute();
  engine.hetu.invoke(
    'Sect',
    namedArgs: {
      'name': name,
      'category': category,
      'genre': genre,
      'headId': GameData.hero['id'],
      'headquarters': atCity,
    },
  );
}

Future<void> _cityhallRecruitCity(
  dynamic location,
  dynamic npc,
  dynamic sect,
  dynamic atCity,
  dynamic heroId,
) async {
  final int development = location['development'];
  final developmentFactor = (development * 2 + 1);
  dialog.pushDialog('hint_createSect_intro', npc: npc, interpolations: [
    kRecruitCityRequirementContribution,
    kRecruitCityRequirementMoney,
    kRecruitCityRequirementShard,
  ]);
  await dialog.execute();
  final heroSect = GameData.getSect(GameData.hero['sectId']);
  bool hasEnemy = false;
  if (heroSect != null) {
    final enemySectIds = heroSect['enemySectIds'] as Iterable? ?? [];
    hasEnemy = enemySectIds.isNotEmpty;
  }
  if (hasEnemy) {
    dialog.pushDialog(
      'hint_recruitCity_atWar',
      npc: npc,
    );
    await dialog.execute();
    return;
  }
  final contribution = GameData.flags['contribution'][atCity['id']];
  final requirementContribution =
      kRecruitCityRequirementContribution * developmentFactor;
  if (contribution < requirementContribution) {
    dialog.pushDialog(
      'hint_notEnoughCityContribution',
      npc: npc,
      interpolations: [
        requirementContribution,
        kRecruitCityRequirementContribution,
      ],
    );
    await dialog.execute();
    return;
  }
  final requirementMoney = kRecruitCityRequirementMoney * developmentFactor;
  final requirementShard = kRecruitCityRequirementShard * developmentFactor;
  final hasMoney = GameData.hero['materials']['money'];
  final hasShard = GameData.hero['materials']['shard'];
  if (hasMoney < requirementMoney || hasShard < requirementShard) {
    dialog.pushDialog('hint_recruitCity_notEnoughMoneyOrShard',
        npc: npc,
        interpolations: [
          requirementMoney,
          requirementShard,
        ]);
    await dialog.execute();
    return;
  }
  dialog.pushDialog('hint_recruitCity_success', npc: npc, interpolations: [
    atCity['name'],
    sect['name'],
  ]);
  await dialog.execute();
  engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
    'money',
    requirementMoney,
  ]);
  engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
    'shard',
    requirementShard,
  ]);
  engine.hetu.invoke(
    'addLocationToSect',
    positionalArgs: [atCity, sect],
  );
  atCity['managerId'] = heroId;
}

Future<void> _cityhallMoveHere(
  dynamic npc,
  dynamic atCity,
) async {
  final cost = kHomeRelocationCost * (atCity['development'] + 1);
  dialog.pushDialog('hint_moveHere', npc: npc, interpolations: [cost]);
  dialog.pushSelectionRaw({
    'id': 'moveHome_confirm',
    'selections': {
      'pay_money': engine.locale('pay_money', interpolations: [cost]),
      'forgetIt': engine.locale('forgetIt'),
    }
  });
  await dialog.execute();
  final selected = dialog.checkSelected('moveHome_confirm');
  if (selected != 'pay_money') return;
  final hasMoney = GameData.hero['materials']['money'];
  if (hasMoney < cost) {
    dialog.pushDialog('hint_notEnough_money', npc: npc);
    await dialog.execute();
    return;
  }
  engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
    'money',
    cost,
  ]);
  engine.hetu.invoke('setHome', namespace: 'Player', positionalArgs: [atCity]);
  dialog.pushDialog('hint_relocatedHome', interpolations: [atCity['name']]);
  await dialog.execute();
}

Future<void> _onInteractSite(
  dynamic location,
  String siteKind,
  bool isAdmin,
) async {
  final siteOptions = <dynamic>[];
  siteOptions.add('siteInformation');

  if (kSiteKindsWorkable.contains(siteKind)) {
    siteOptions.add({
      'text': 'work',
      'description': 'hint_work_description',
    });
  }
  if (kProductionSiteKinds.contains(siteKind) &&
      kSiteWorkableStaminaCost.containsKey(siteKind)) {
    siteOptions.add({
      'text': 'produce',
      'description': 'hint_produce_description',
    });
  }
  if (kSiteKindsTradable.contains(siteKind)) {
    siteOptions.add('trade');
  }
  if (siteKind == 'tradinghouse' || kProductionSiteKinds.contains(siteKind)) {
    siteOptions.add('tradeMaterial');
  } else if (siteKind == 'workshop') {
    siteOptions.add('workbench');
  } else if (siteKind == 'divinationaltar') {
    siteOptions.add('divination');
  } else if (siteKind == 'arena') {
    siteOptions.add('about_arena');
  } else if (siteKind == 'dungeon') {
    siteOptions.add('about_dungeon');
  }
  siteOptions.add('cancel');

  dialog.pushSelection(siteKind, siteOptions);
  await dialog.execute();
  final selected = dialog.checkSelected(siteKind);
  switch (selected) {
    case 'siteInformation':
      engine.context.read<ViewPanelState>().toogle(
        ViewPanels.siteInformation,
        arguments: {
          'site': location,
          'isAdmin': isAdmin,
        },
      );
    case 'work':
      _heroWork(location);
    case 'produce':
      _heroProduce(location);
    case 'tradeMaterial':
      engine.context.read<MerchantState>().show(
            location,
            materialMode: true,
            useShard: false,
            priceFactor: location['priceFactor'],
            merchantType: kProductionSiteKinds.contains(siteKind)
                ? MerchantType.productionSite
                : MerchantType.location,
          );
    case 'trade':
      engine.context.read<MerchantState>().show(
            location,
            materialMode: false,
            useShard: siteKind != 'tradinghouse',
            priceFactor: location['priceFactor'],
            merchantType: MerchantType.location,
            allowManualReplenish: true,
          );
    case 'workbench':
      engine.context.read<ViewPanelState>().toogle(
        ViewPanels.workbench,
        arguments: {'location': location},
      );
    case 'about_dungeon':
      dialog.pushDialog(
        'hint_dungeonEntrance',
        npcId: location['npcId'],
      );
      await dialog.execute();
    case 'about_arena':
      dialog.pushDialog(
        'hint_arenaEntrance',
        npcId: location['npcId'],
      );
      await dialog.execute();
    case 'divination':
      await _heroDivination(location);
  }
}

Future<void> _onInteractCharacter(dynamic character) async {
  if (character == GameData.hero) return;

  if (character['entityType'] == 'npc') {
    final location = engine.hetu.fetch('location');
    _onInteractNpc(location);
    return;
  } else if (character['entityType'] != 'character') {
    engine.error('invalid character entity type, ${character['entityType']}');
    return;
  }

  engine.info('正在和角色 [${character['name']}] 互动。');

  final result = await engine.hetu.invoke('onGameEvent',
      positionalArgs: ['onBeforeInteractCharacter', character]);
  if (result == true) {
    return result;
  }

  final bond = engine.hetu
      .invoke('characterMet', positionalArgs: [character, GameData.hero]);
  if (bond['score'] < 0) {
    // TODO: 商人不会因为好感低而拒绝交易
    dialog.pushDialog('discourse_unfavorRefusal', character: character);
    await dialog.execute();
    return;
  }

  final selections = [
    'characterInformation',
    'talk',
    'trade',
    'show',
  ];
  final hasGifted =
      GameData.checkMonthly(MonthlyActivityIds.gifted, character.id);
  final hasAttacked =
      GameData.checkMonthly(MonthlyActivityIds.attacked, character.id);
  final hasStolen =
      GameData.checkMonthly(MonthlyActivityIds.stolen, character.id);
  if (!hasGifted) selections.add('gift');
  if (!hasAttacked) selections.add('attack');
  if (!hasStolen) selections.add('steal');
  selections.add('bye');
  dialog.pushSelection(
    'characterInteraction',
    selections,
  );
  await dialog.execute();
  final selected = dialog.checkSelected('characterInteraction');

  bool interacted = true;
  switch (selected) {
    case 'characterInformation':
      interacted = false;
      await showDialog(
        context: engine.context,
        builder: (context) => CharacterProfileView(
          character: character,
        ),
      );
    case 'talk':
      dialog.pushSelection(
        'topicSelections',
        ['chitchat', 'journalTopic', 'objectiveTopic', 'cancel'],
      );
      await dialog.execute();
      final topic = dialog.checkSelected('topicSelections');
      if (topic == null || topic == 'cancel') {
        interacted = false;
        return;
      }
      switch (topic) {
        case 'chitchat':
          interacted = false;
          final prompt = GameData.getLlmChatSystemPrompt2(character);
          GameUI.showLlmChat(
            engine.context,
            systemPrompt: prompt,
            npc: character,
          );
        case 'journalTopic':
          final journalsData = GameData.hero['journals'];
          final journalsSelections = {};
          for (final journal in journalsData.values) {
            if (journal['isFinished'] == true) continue;
            journalsSelections[journal['id']] = journal['title'];
          }
          if (journalsData.isEmpty || journalsSelections.isEmpty) {
            dialog.pushDialog('hint_noJournals', isHero: true);
            await dialog.execute();
            return;
          }
          journalsSelections['forgetIt'] = engine.locale('forgetIt');
          dialog.pushSelectionRaw(
              {'id': 'journalSelections', 'selections': journalsSelections});
          await dialog.execute();
          final selectedJournalId = dialog.checkSelected('journalSelections');
          if (selectedJournalId == null || selectedJournalId == 'forgetIt') {
            interacted = false;
            return;
          }
          // final selectedJournal = journalsData[selectedJournalId];
          final result = await engine.hetu.invoke('onGameEvent',
              positionalArgs: [
                'onInquiryJournal',
                character,
                journalsData[selectedJournalId]
              ]);
          if (result == true) return;
          bool topicRejected = true;
          switch (selectedJournalId) {
            case 'sectInitiation':
              if (character['sectId'] == GameData.hero['sectId']) {
                topicRejected = false;
                final sect = GameData.game['sects'][character['sectId']];
                assert(
                    sect != null, 'sect is null, id: ${character['sectId']}');
                final memberData = sect['membersData'][GameData.hero['id']];
                assert(memberData != null,
                    'memberData is null, sect id: [${character['sectId']}], character id: ${GameData.hero['id']}');
                final reportSiteId = memberData['reportSiteId'];
                final reportSite = GameData.getLocation(reportSiteId);
                final superiorId = memberData['superiorId'];
                assert(superiorId != null,
                    'hero\'s superiorId is null, sect id: [${character['sectId']}]');
                final superior = GameData.getCharacter(superiorId);
                if (superiorId == character['id']) {
                  dialog.pushDialog(
                    'topic_sectInitiation_superior',
                    character: character,
                    interpolations: [
                      sect['name'],
                      reportSite['name'],
                    ],
                  );
                  await dialog.execute();
                } else {
                  dialog.pushDialog(
                    'topic_sectInitiation',
                    character: character,
                    interpolations: [
                      sect['name'],
                      reportSite['name'],
                      superior['name'],
                    ],
                  );
                  await dialog.execute();
                }
              }
          }
          if (topicRejected) {
            dialog.pushDialog('discourse_defaultUnknown', character: character);
            await dialog.execute();
          }
        case 'objectiveTopic':
          final familyRelationships = GameData.hero['familyRelationships'];
          final shituRelationships = GameData.hero['shituRelationships'];
          final relationshipSelections = [];

          /// 玩家角色并不能主动发起浪漫关系
          /// 只能有概率的被动触发 NPC 爱上自己的事件
          /// 只有对方爱上自己的情况下，才可以创建婚姻关系
          final bool isCharacterSpouse =
              familyRelationships['spouseIds'].contains(character['id']);
          if (!isCharacterSpouse) {
            final bool isCharacterRomance =
                GameData.hero['romanceIds'].contains(character['id']);
            if (isCharacterRomance) {
              final bool hasProposed = GameData.checkMonthly(
                  MonthlyActivityIds.proposed, character['id']);
              if (!hasProposed) {
                relationshipSelections.add('propose');
              }
            }
          } else {
            relationshipSelections.add('divorce');
          }

          // 师徒关系的传授功法
          final bool isCharacterShifu =
              shituRelationships['shifuIds'].contains(character['id']);
          final bool isCharacterTudi =
              shituRelationships['tudiIds'].contains(character['id']);
          // 不允许既是师父又是徒弟
          assert(!(isCharacterShifu && isCharacterTudi));
          final bool hasConsulted =
              GameData.checkMonthly(MonthlyActivityIds.consulted, character.id);
          final bool hasTutored =
              GameData.checkMonthly(MonthlyActivityIds.tutored, character.id);
          if (isCharacterShifu) {
            if (!hasConsulted) {
              relationshipSelections.add('consult');
            }
          } else if (isCharacterTudi) {
            if (!hasTutored) {
              relationshipSelections.add('tutor');
            }
          } else {
            final int heroLevel = GameData.hero['level'];
            final int heroRank = GameData.hero['rank'];
            final int characterLevel = character['level'];
            final int characterRank = character['rank'];
            if (characterLevel > heroLevel && characterRank > heroRank) {
              final bool hasBaishi = GameData.checkMonthly(
                  MonthlyActivityIds.baishi, character.id);
              if (!hasBaishi) {
                relationshipSelections.add('baishi');
              }
            } else if (heroLevel > characterLevel && heroRank > characterRank) {
              final bool hasShoutu = GameData.checkMonthly(
                  MonthlyActivityIds.shoutu, character.id);
              if (!hasShoutu) {
                relationshipSelections.add('shoutu');
              }
            }
          }

          // 门派成员招募
          if (GameData.hero['sectId'] != null && character['sectId'] == null) {
            final bool isHeroHead = GameData.hero['sectId'] != null &&
                GameData.game['sects'][GameData.hero['sectId']]['headId'] ==
                    GameData.hero['id'];
            final bool hasRecruited = GameData.checkMonthly(
                MonthlyActivityIds.recruited, character['id']);
            if (isHeroHead && !hasRecruited) {
              relationshipSelections.add('recruit');
            }
          }
          relationshipSelections.add('forgetIt');
          dialog.pushSelection(
            'characterRelationshipInteraction',
            relationshipSelections,
          );
          await dialog.execute();
          final selected2 =
              dialog.checkSelected('characterRelationshipInteraction');
          if (selected2 == null || selected2 == 'forgetIt') {
            interacted = false;
            return;
          }
          switch (selected2) {
            case 'propose':
              {}
            case 'divorce':
              {}
            case 'consult':
              {}
            case 'tutor':
              {}
            case 'baishi':
              {}
            case 'shoutu':
              {}
            case 'apply':
              {}
            case 'recruit':
              {}
          }
      }
    case 'show':
      // 向角色展示某个物品
      final items = await GameLogic.selectItem(
          character: GameData.hero, multiSelect: false);
      final item = items.firstOrNull;
      if (item == null) return;
      engine.info('正在向 ${character['name']} 出示 ${item['name']}');
      engine.hetu
          .invoke('onGameEvent', positionalArgs: ['onShow', character, item]);
    case 'gift':
      final items = await GameLogic.selectItem(
          character: GameData.hero, multiSelect: false);
      final item = items.first;
      if (item != null) {
        engine.info('正在向 ${character.name} 赠送 ${item.name}');
        final result = await engine.hetu
            .invoke('onGameEvent', positionalArgs: ['onGift', character, item]);
        if (result) {
          engine.hetu
              .invoke('lose', namespace: 'Player', positionalArgs: [item]);
          engine.hetu
              .invoke('entityAcquire', positionalArgs: [character, item]);
          dialog.pushDialog('discourse_giftAcception', character: character);
          await dialog.execute();
        } else {
          dialog.pushDialog('discourse_giftRefusal', character: character);
          await dialog.execute();
        }
      }
    case 'trade':
      interacted = false;
      // TODO:
      // 根据好感度决定折扣
      // 根据角色技能决定不同物品的折扣
      // 根据角色境界决定使用铜钱还是灵石交易
      double baseRate = kBuyRateBase;
      final sellRateModifier =
          (bond['score'] * kPriceFavorRate) * kPriceFavorIncrement;
      baseRate -= sellRateModifier;
      if (baseRate < kMinBuyRate) {
        baseRate = kMinBuyRate;
      }
      double sellRate = kSellRateBase;
      sellRate += sellRateModifier;
      if (sellRate < kMinSellRate) {
        sellRate = kMinSellRate;
      }
      engine.context.read<MerchantState>().show(
            character,
            useShard: true,
            priceFactor: <String, dynamic>{
              'base': baseRate,
              'sell': sellRate,
            },
            merchantType: MerchantType.character,
          );
    case 'attack':
      {}
    case 'steal':
      {}
  }

  if (interacted && !GameData.hero['companions'].contains(character['id'])) {
    // 任何互动操作后，隐藏该角色不能再次互动
    dialog.pushDialog(engine.locale('discourse_bye'), character: character);
    await dialog.execute();
    gameState.hideNpc(character['id']);
    character['locationId'] = character['homeSiteId'];
  }
}

/// 为某个角色解锁某个天赋树节点
/// 注意这里不会检查和处理技能点，而是直接增加某个天赋
bool _characterUnlockPassiveTreeNode(
  dynamic character,
  String nodeId, {
  String? selectedAttributeId,
}) {
  final unlockedNodes = character['unlockedPassiveTreeNodes'];
  if (unlockedNodes[nodeId] != null) {
    return false;
  }

  final passiveTreeNodeData = GameData.passiveTree[nodeId];
  if (passiveTreeNodeData == null) {
    engine.warning('天赋树节点 $nodeId 不存在');
    return false;
  }
  bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;

  if (selectedAttributeId == null) {
    final r = GameData.random.nextDouble();
    if (r < 0.4) {
      selectedAttributeId = character['mainAttribute'];
    } else {
      selectedAttributeId = GameData.random.nextIterable(kBattleAttributes);
    }
  } else {
    assert(kBattleAttributes.contains(selectedAttributeId));
  }
  assert(selectedAttributeId != null);

  if (isAttribute) {
    // 属性点类的node，记录的是选择的具体属性的名字
    unlockedNodes[nodeId] = selectedAttributeId;
    engine.hetu.invoke(
      'characterSetPassive',
      positionalArgs: [character, selectedAttributeId],
      namedArgs: {'level': kPassiveTreeAttributeAnyLevel},
    );
  } else {
    unlockedNodes[nodeId] = true;
    final List nodePassiveData = passiveTreeNodeData['passives'];
    for (final data in nodePassiveData) {
      engine.hetu.invoke(
        'characterSetPassive',
        positionalArgs: [character, data['id']],
        namedArgs: {'level': data['level'] ?? 1},
      );
    }
  }

  return true;
}

void _characterRefundPassiveTreeNode(
  dynamic character,
  String nodeId,
) {
  final passiveTreeNodeData = GameData.passiveTree[nodeId];
  final unlockedNodes = character['unlockedPassiveTreeNodes'];
  bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;

  if (isAttribute) {
    final attributeId = unlockedNodes[nodeId];
    assert(kBattleAttributes.contains(attributeId));
    // engine.hetu.invoke('refundPassive',
    //     namespace: 'Player', positionalArgs: ['lifeMax']);
    engine.hetu.invoke(
      'characterSetPassive',
      positionalArgs: [character, attributeId],
      namedArgs: {'level': -kPassiveTreeAttributeAnyLevel},
    );
  } else {
    final List nodePassiveData = passiveTreeNodeData['passives'];
    for (final data in nodePassiveData) {
      engine.hetu.invoke(
        'characterSetPassive',
        positionalArgs: [character, data['id']],
        namedArgs: {'level': -(data['level'] ?? 1)},
      );
    }
  }
  unlockedNodes.remove(nodeId);
}

void _characterAllocateSkills(dynamic character, {bool rejuvenate = true}) {
  final genre = character['cultivationFavor'];
  final style = character['cultivationStyle'];
  final int rank = character['rank'];
  final int level = character['level'];

  int count = 0;
  final List<String>? rankPath = kCultivationRankPaths[genre];
  if (rankPath == null) {
    engine.warning('修炼流派 $genre 的 rankPath 不存在');
  } else {
    final List<String>? stylePath = kCultivationStylePaths[genre]?[style];
    assert(stylePath != null, 'genre: $genre, style: $style');

    for (var i = 0; i < rank; ++i) {
      assert(i < rankPath.length);
      final nodeId = rankPath[i];
      final unlocked =
          GameLogic.characterUnlockPassiveTreeNode(character, nodeId);
      if (unlocked) {
        count++;
      }
    }

    for (var i = 0; i < level - rank; ++i) {
      assert(i < stylePath!.length);
      final nodeId = stylePath![i];
      final unlocked =
          GameLogic.characterUnlockPassiveTreeNode(character, nodeId);
      if (unlocked) {
        count++;
      }
    }
  }

  engine.hetu.invoke('characterCalculateStats', positionalArgs: [
    character
  ], namedArgs: {
    'rejuvenate': rejuvenate,
  });

  engine.info(
      '${character['name']} (rank: ${character['rank']}, level: ${character['level']}) 在 ${engine.locale('genre')} ${engine.locale(genre)} 的 ${engine.locale(style)} 路线上解锁了 $count 个天赋树节点');
}
