part of 'logic.dart';

void _heroRest() async {
  dialog.pushSelection('restOption', [
    'restTillTommorow',
    'rest1Days',
    'rest10Days',
    'rest30Days',
    'restTillNextMonth',
    'restTillFullHealth',
    'cancel',
  ]);
  await dialog.execute();
  final selected = dialog.checkSelected('restOption');

  int ticks = 0;
  switch (selected) {
    case 'restTillTommorow':
      ticks = kTicksPerDay - GameLogic.ticksOfDay;
    case 'rest1Days':
      ticks = kTicksPerDay;
    case 'rest10Days':
      ticks = kTicksPerDay * 10;
    case 'rest30Days':
      ticks = kTicksPerDay * 30;
    case 'restTillNextMonth':
      ticks = kTicksPerMonth - GameLogic.ticksOfMonth;
    case 'restTillFullHealth':
      ticks =
          (GameData.hero['stats']['lifeMax'] - GameData.hero['life']).floor();
      if (ticks <= 0) {
        dialog.pushDialog('hint_alreadyFullHealthNoNeedRest');
        await dialog.execute();
      }
  }
  if (ticks <= 0) return;

  TimeflowDialog.show(
    context: engine.context,
    max: ticks,
    onProgress: () {
      engine.hetu
          .invoke('restoreLife', namespace: 'Player', positionalArgs: [1]);
      return GameData.hero['life'] >= GameData.hero['stats']['lifeMax'];
    },
  );
}

void _notEnoughStamina([dynamic npc]) async {
  dialog.pushDialog(
    'hint_notEnoughHealthToWork',
    name: npc?['name'],
    icon: npc?['icon'],
    image: npc?['image'],
  );
  await dialog.execute();
}

Future<void> _heroProduce(dynamic location) async {
  final siteKind = location['kind'];
  assert(
      kSiteKindsBuildableOnWorldMap.contains(siteKind) &&
          kSiteWorkableBaseStaminaCost.containsKey(siteKind),
      '非可生产场所：${location['name']} ($siteKind)');

  final isRented = await _checkRented(location);
  if (!isRented) return;

  dialog.pushSelection('produceOption', [
    'produce5Days',
    'produce15Days',
    'produceTillNextMonth',
    'produceTillEmptyHealth',
    'cancel',
  ]);
  await dialog.execute();
  final selected = dialog.checkSelected('produceOption');
  if (selected == 'cancel') return;

  int staminaCost = kSiteWorkableBaseStaminaCost[siteKind]!;
  int life = GameData.hero['life'];

  if (life <= staminaCost) {
    dialog.pushDialog('hint_notEnoughHealthToWork');
    await dialog.execute();
    return;
  }

  int maxAffordableTicks = life ~/ staminaCost;
  int availableTicksTillNextMonth = kTicksPerMonth - GameLogic.ticksOfMonth;
  final maxTicks = math.min(maxAffordableTicks, availableTicksTillNextMonth);

  int ticks = 0;
  switch (selected) {
    case 'produce5Days':
      ticks = kTicksPerDay * 5;
    case 'produce15Days':
      ticks = kTicksPerDay * 15;
    case 'produceTillNextMonth':
      ticks = availableTicksTillNextMonth;
    case 'produceTillEmptyHealth':
      ticks = maxAffordableTicks;
  }
  final finalTicks = math.min(ticks, maxTicks);
  if (finalTicks <= 0) return;

  // 该建筑所能产出的资源类型及其概率
  assert(kSiteKindsToMaterialProducable.containsKey(siteKind));
  final materialData = kSiteKindsToMaterialProducable[siteKind]!;

  // 该地块所拥有的资源类型及其丰富度
  final terrain = GameData.getTerrain(location['terrainIndex']);
  final resourceData = terrain['resources'];

  final produced = <String, int>{};
  final r = math.Random();

  await TimeflowDialog.show(
    context: engine.context,
    max: ticks,
    onProgress: () {
      final roll = r.nextDouble();
      for (String key in materialData.keys) {
        final double chance = materialData[key]!;
        if (roll <= chance) {
          final int abundance = resourceData[key] ?? 0;
          final int amount = (abundance ~/ kTicksPerDay);
          produced[key] = (produced[key] ?? 0) + amount;
        }
      }
      engine.hetu.invoke('setLife',
          namespace: 'Player',
          positionalArgs: [GameData.hero['life'] - staminaCost]);
      return GameData.hero['life'] <= staminaCost;
    },
  );

  engine.play('pickup_item-64282.mp3');
  engine.hetu
      .invoke('collectAll', namespace: 'Player', positionalArgs: [produced]);
}

Future<void> _heroWork(dynamic location, dynamic npc) async {
  final kind = location['kind'];
  if (!kSiteKindsWorkable.contains(kind)) {
    engine.error('非可工作场所：${location['name']} ($kind)');
    return;
  }

  // 非门派成员，只能在一年中的指定时间打工
  // 门派成员则不受时间限制
  if (location['organizationId'] != null &&
      location['organizationId'] != GameData.hero['organizationId']) {
    final months = kSiteWorkableMounths[kind] as List;
    if (!months.contains(GameLogic.month)) {
      dialog.pushDialog(
        'hint_notWorkSeason',
        name: npc?['name'],
        icon: npc?['icon'],
        image: npc?['image'],
      );
      await dialog.execute();
      return;
    }
  }

  if (GameData.hero['life'] <= 1) {
    _notEnoughStamina(npc);
    return;
  }

  final int salary = kSiteWorkableBaseSalaries[kind]!;
  final int staminaCost = kSiteWorkableBaseStaminaCost[kind]!;

  dialog.pushSelection('workOption', [
    'work10Days',
    'work30Days',
    'workTillNextMonth',
    'workTillHealthExhausted',
    'cancel',
  ]);
  await dialog.execute();
  final selected = dialog.checkSelected('workOption');
  int ticks = 0;
  switch (selected) {
    case 'work10Days':
      ticks = kTicksPerDay * 10;
    case 'work30Days':
      ticks = kTicksPerDay * 30;
    case 'workTillNextMonth':
      ticks = kTicksPerMonth - GameLogic.ticksOfMonth;
    case 'workTillHealthExhausted':
      ticks = (GameData.hero['life'] ~/ staminaCost) - 1;
      if (ticks <= 0) {
        _notEnoughStamina(npc);
        return;
      }
  }
  if (ticks <= 0) return;

  final finalTicks = await TimeflowDialog.show(
    context: engine.context,
    max: ticks,
    onProgress: () {
      engine.hetu.invoke('setLife',
          namespace: 'Player',
          positionalArgs: [GameData.hero['life'] - staminaCost]);
      return GameData.hero['life'] <= staminaCost;
    },
  );

  engine.play('coins-31879.mp3');
  engine.hetu.invoke('collect', namespace: 'Player', positionalArgs: [
    'money'
  ], namedArgs: {
    'amount': finalTicks * salary,
  });
}

Future<void> _onInteractNpc(dynamic npc, dynamic location) async {
  engine.debug('正在和 NPC [${npc['id']}] 互动。');
  if (npc['useCustomLogic'] == true) {
    engine.debug('NPC [${npc.id}] 使用自定义逻辑。');
    engine.hetu.invoke('onGameEvent',
        positionalArgs: ['onInteractNpc', npc, location]);
    return;
  }

  /// 这里的 organization 可能是 null
  final organization =
      GameData.game['organizations'][location['organizationId']];

  /// 这里的 atLocation 可能是 null
  final atLocation = GameData.game['locations'][location['atLocationId']];

  bool isManager = GameData.hero['id'] == location['ownerId'];
  bool isMayor = GameData.hero['id'] == atLocation?['ownerId'];
  bool isHead = GameData.hero['id'] == organization['headId'];

  bool hasAuthority = isManager || isMayor || isHead;

  final siteKind = location['kind'];
  if (siteKind == 'headquarters') {
    dialog.pushSelection(siteKind, [
      'organizationInformation',
      'organizationRelationshipDiscourse',
      'cancel',
    ]);
    await dialog.execute();
    final selected = dialog.checkSelected(siteKind);
    switch (selected) {
      case 'organizationInformation':
        showDialog(
          context: engine.context,
          builder: (context) => OrganizationView(
            organization: organization,
            mode: hasAuthority
                ? InformationViewMode.manage
                : InformationViewMode.view,
          ),
        );
      case 'organizationRelationshipDiscourse':
        final relationshipSelections = [];
        final heroOrganizationId = GameData.hero['organizationId'];
        if (heroOrganizationId == null) {
          relationshipSelections.add('enroll');
        } else {
          if (heroOrganizationId == organization['id']) {
            relationshipSelections.add('resign');
          } else {
            final heroTitleId = GameData.hero['titleId'];
            if (heroTitleId == 'head' || heroTitleId == 'diplomat') {
              final heroOrganization =
                  GameData.getOrganization(heroOrganizationId);
              final diplomacyDataId = organization['diplomacies']
                  [heroOrganizationId][heroOrganizationId];
              if (diplomacyDataId == null) {
                engine.hetu.invoke(
                  'createDiplomacy',
                  positionalArgs: [heroOrganization, organization],
                  namedArgs: {
                    'type': 'neutral',
                    'score': kDiplomacyDefaultScore,
                  },
                );
              }

              final diplomacyData =
                  GameData.game['diplomacies'][diplomacyDataId];
              assert(diplomacyData != null);
              final String type = diplomacyData['type'];
              final score = diplomacyData['score'] as int;
              switch (type) {
                case 'ally':
                  relationshipSelections.add('breakAlliance');
                case 'enemy':
                  relationshipSelections.add('startPeaceTalk');
                case 'neutral':
                  if (score >= kDiplomacyScoreAllyThreshold) {
                    relationshipSelections.add('formAlliance');
                  } else if (score <= kDiplomacyScoreEnemyThreshold) {
                    relationshipSelections.add('declareWar');
                  }
                  relationshipSelections.add('gift');
                  relationshipSelections.add('askHelp');
              }
            }
          }
        }

        relationshipSelections.add('forgetIt');
        dialog.pushSelection(
            'organizationRelationship', relationshipSelections);
        await dialog.execute();
        final selected = dialog.checkSelected('organizationRelationship');
        switch (selected) {
          case 'enroll':
            if (GameData.game['playerMonthly']['enrolled']
                .contains(organization['id'])) {
              dialog.pushDialog('hint_alreadyTrialedThisMonth',
                  name: npc['name'],
                  icon: npc['icon'],
                  image: npc['illustration']);
              return;
            }
            final organizationCategory = organization['category'];
            assert(kOrganizationCategories.contains(organizationCategory));
            dialog.pushDialog(
              'organization_${organizationCategory}_trial_intro',
              name: npc['name'],
              icon: npc['icon'],
              image: npc['illustration'],
            );
            await dialog.execute();
            switch (organizationCategory) {
              case 'wuwei':
                bool passed = true;
                final questions =
                    List<int>.generate(kWuweiTrialQuestionCount, (i) => i + 1);
                questions.shuffle();
                final selectedQuestions = questions.skip(5);
                for (final q in selectedQuestions) {
                  final qString = 'organization_wuwei_trial_question_$q';
                  dialog.pushDialog(
                    qString,
                    name: npc['name'],
                    icon: npc['icon'],
                    image: npc['illustration'],
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
                    name: npc['name'],
                    icon: npc['icon'],
                    image: npc['illustration'],
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
                    'organization_${organizationCategory}_trial_pass',
                    name: npc['name'],
                    icon: npc['icon'],
                    image: npc['illustration'],
                  );
                  await dialog.execute();
                  await engine.hetu.invoke(
                    'enroll',
                    namespace: 'Player',
                    positionalArgs: [organization],
                    namedArgs: {
                      'npcId': npc['id'],
                    },
                  );
                } else {
                  GameData.game['playerMonthly']['enrolled']
                      .add(organization['id']);
                  dialog.pushDialog(
                    'organization_${organizationCategory}_trial_fail',
                    name: npc['name'],
                    icon: npc['icon'],
                    image: npc['illustration'],
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
                });
                engine.hetu
                    .invoke('characterCalculateStats', positionalArgs: [enemy]);
                // engine.hetu.invoke('generateDeck', positionalArgs: [enemy]);
                engine.hetu.invoke('generateDeck', positionalArgs: [
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
                engine.context.read<EnemyState>().show(enemy,
                    onBattleEnd: (bool battleResult, int roundCount) async {
                  if (roundCount <= kCultivationTrialMinBattleRound) {
                    dialog.pushDialog(
                      'organization_${organizationCategory}_trial_pass',
                      name: npc['name'],
                      icon: npc['icon'],
                      image: npc['illustration'],
                    );
                    await dialog.execute();
                    await engine.hetu.invoke(
                      'enroll',
                      namespace: 'Player',
                      positionalArgs: [organization],
                      namedArgs: {
                        'npcId': npc['id'],
                      },
                    );
                  } else {
                    GameData.game['playerMonthly']['enrolled']
                        .add(organization['id']);
                    dialog.pushDialog(
                      'organization_${organizationCategory}_trial_fail',
                      name: npc['name'],
                      icon: npc['icon'],
                      image: npc['illustration'],
                    );
                    await dialog.execute();
                  }
                });
              case 'immortality':
                GameData.game['flags']['cultivationTrial'] = {
                  'difficulty': 0,
                  'introCompleted': false,
                  'buildCompleted': false,
                  'room': 0,
                  'organizationId': organization['id'],
                  'npcId': npc['id'],
                };
                engine.pushScene(
                  'cultivation_trial_1',
                  constructorId: Scenes.worldmap,
                  arguments: {
                    'id': 'cultivation_trial_1',
                    'method': 'load',
                  },
                );
              case 'chivalry':
                final enemy = engine.hetu.invoke('Character', namedArgs: {
                  'rank': GameData.hero['rank'],
                });
                engine.hetu
                    .invoke('characterCalculateStats', positionalArgs: [enemy]);
                engine.hetu.invoke('generateDeck', positionalArgs: [enemy]);
                engine.context.read<EnemyState>().show(
                  enemy,
                  // prebattlePreventClose: true,
                  onBattleEnd: (bool battleResult, int roundCount) async {
                    if (battleResult) {
                      dialog.pushDialog(
                        'organization_${organizationCategory}_trial_pass',
                        name: npc['name'],
                        icon: npc['icon'],
                        image: npc['illustration'],
                      );
                      await dialog.execute();
                      await engine.hetu.invoke(
                        'enroll',
                        namespace: 'Player',
                        positionalArgs: [organization],
                        namedArgs: {
                          'npcId': npc['id'],
                        },
                      );
                    } else {
                      GameData.game['playerMonthly']['enrolled']
                          .add(organization['id']);
                      dialog.pushDialog(
                        'organization_${organizationCategory}_trial_fail',
                        name: npc['name'],
                        icon: npc['icon'],
                        image: npc['illustration'],
                      );
                      await dialog.execute();
                    }
                  },
                );
              case 'entrepreneur':
                final List testersData =
                    organization['members'].values.where((m) {
                  if (m['rank'] >= 1) return true;
                }).toList();
                assert(testersData.isNotEmpty);
                testersData.sort((a, b) => a['rank'].compareTo(b['rank']));
                final tester = testersData.first;
                engine.context.read<EnemyState>().show(
                  tester,
                  // prebattlePreventClose: true,
                  onBattleEnd: (bool battleResult, int roundCount) async {
                    if (battleResult) {
                      dialog.pushDialog(
                        'organization_${organizationCategory}_trial_pass',
                        name: npc['name'],
                        icon: npc['icon'],
                        image: npc['illustration'],
                      );
                      await dialog.execute();
                      await engine.hetu.invoke(
                        'enroll',
                        namespace: 'Player',
                        positionalArgs: [organization],
                        namedArgs: {
                          'npcId': npc['id'],
                        },
                      );
                    } else {
                      GameData.game['playerMonthly']['enrolled']
                          .add(organization['id']);
                      dialog.pushDialog(
                        'organization_${organizationCategory}_trial_fail',
                        name: npc['name'],
                        icon: npc['icon'],
                        image: npc['illustration'],
                      );
                      await dialog.execute();
                    }
                  },
                );
              case 'wealth':
                final int cost = kWealthTrialCost;
                dialog.pushDialog('organization_wealth_intro',
                    name: npc['name'],
                    icon: npc['icon'],
                    image: npc['illustration'],
                    interpolations: [cost]);
                await dialog.execute();
                final weathTrialSelections = [
                  'pay_shard',
                  'forgetIt',
                ];
                dialog.pushSelection(
                    'organization_wealth_trial', weathTrialSelections);
                await dialog.execute();
                final selected =
                    dialog.checkSelected('organization_wealth_trial');
                if (selected == 'pay_shard') {
                  final int shard = GameData.hero['materials']['shard'] ?? 0;
                  if (shard >= cost) {
                    engine.hetu.invoke(
                      'exhaust',
                      namespace: 'Player',
                      positionalArgs: ['shard'],
                      namedArgs: {'amount': cost},
                    );
                    dialog.pushDialog(
                      'organization_${organizationCategory}_trial_pass',
                      name: npc['name'],
                      icon: npc['icon'],
                      image: npc['illustration'],
                    );
                    await dialog.execute();
                    await engine.hetu.invoke(
                      'enroll',
                      namespace: 'Player',
                      positionalArgs: [organization],
                      namedArgs: {
                        'npcId': npc['id'],
                      },
                    );
                  } else {
                    dialog.pushDialog('hint_notEnoughShard');
                    dialog.pushDialog(
                      'organization_${organizationCategory}_trial_fail',
                      name: npc['name'],
                      icon: npc['icon'],
                      image: npc['illustration'],
                    );
                    await dialog.execute();
                  }
                }
              case 'pleasure':
                final heroCharisma = GameData.hero['stats']['charisma'];
                if (heroCharisma >= kPleasureTrialMinCharisma) {
                  dialog.pushDialog(
                    'organization_${organizationCategory}_trial_pass',
                    name: npc['name'],
                    icon: npc['icon'],
                    image: npc['illustration'],
                  );
                  await dialog.execute();
                  await engine.hetu.invoke(
                    'enroll',
                    namespace: 'Player',
                    positionalArgs: [organization],
                    namedArgs: {
                      'npcId': npc['id'],
                    },
                  );
                } else {
                  dialog.pushDialog(
                    'organization_${organizationCategory}_trial_fail',
                    name: npc['name'],
                    icon: npc['icon'],
                    image: npc['illustration'],
                  );
                  await dialog.execute();
                }
            }
          case 'resign':
            final resignSelections = [
              'resign_confirm',
              'forgetIt',
            ];
            dialog.pushSelection('resign_selections', resignSelections);
            final selected = dialog.checkSelected('resign_selections');
            if (selected == 'resign_confirm') {
              engine.hetu.invoke(
                'removeCharacterFromOrganization',
                positionalArgs: [GameData.hero],
              );
              dialog.pushDialog('hint_organization_resign',
                  interpolations: [organization['name']]);
              await dialog.execute();
            }
          case 'formAlliance':
          case 'breakAlliance':
          case 'makePeace':
          case 'declareWar':
          case 'gift':
          case 'askHelp':
        }
    }
  } else {
    final siteOptions = <dynamic>[];
    if (siteKind == 'headquarters') {
      siteOptions.add('organizationInformation');
    } else if (siteKind == 'cityhall') {
      siteOptions.add('cityInformation');
    } else {
      siteOptions.add('siteInformation');
    }

    if (kSiteKindsWorkable.contains(siteKind)) {
      siteOptions.add({
        'text': 'work',
        'description': 'hint_work_description',
      });
    }
    if (kSiteKindsBuildableOnWorldMap.contains(siteKind) &&
        kSiteWorkableBaseStaminaCost.containsKey(siteKind)) {
      siteOptions.add({
        'text': 'produce',
        'description': 'hint_produce_description',
      });
    }
    if (kSiteKindsTradable.contains(siteKind)) {
      siteOptions.add('trade');
    }
    if (siteKind == 'cityhall') {
      siteOptions.add('bounty');
    } else if (siteKind == 'tradinghouse') {
      siteOptions.add('tradeMaterial');
    } else if (siteKind == 'workshop') {
      siteOptions.add('workbench');
    } else if (siteKind == 'alchemylab') {
      siteOptions.add('alchemy_furnace');
    }
    siteOptions.add('cancel');

    dialog.pushSelection(
      siteKind,
      siteOptions,
    );
    await dialog.execute();
    final selected = dialog.checkSelected(siteKind);
    switch (selected) {
      case 'organizationInformation':
        showDialog(
          context: engine.context,
          builder: (context) => OrganizationView(
            organization: organization,
            mode: hasAuthority
                ? InformationViewMode.manage
                : InformationViewMode.view,
          ),
        );
      case 'cityInformation':
        showDialog(
          context: engine.context,
          builder: (context) => LocationView(
            location: atLocation,
            mode: hasAuthority
                ? InformationViewMode.manage
                : InformationViewMode.view,
          ),
        );
      case 'siteInformation':
        showDialog(
          context: engine.context,
          builder: (context) => LocationView(
            location: location,
            mode: hasAuthority
                ? InformationViewMode.manage
                : InformationViewMode.view,
          ),
        );
      case 'work':
        _heroWork(location, npc);
      case 'produce':
        _heroProduce(location);
      case 'bounty':
        showDialog(
          context: engine.context,
          builder: (context) => BountyView(
            data: location['bounty'] ?? const [],
          ),
        );
      case 'tradeMaterial':
        engine.context.read<MerchantState>().show(
              location,
              materialMode: true,
              useShard: false,
              priceFactor: location['priceFactor'],
            );
      case 'trade':
        engine.context.read<MerchantState>().show(
              location,
              materialMode: false,
              useShard: siteKind != 'tradinghouse',
              priceFactor: location['priceFactor'],
            );
      case 'workbench':
        engine.context.read<ViewPanelState>().toogle(ViewPanels.workbench);
      case 'alchemy_furnace':
        engine.context.read<ViewPanelState>().toogle(ViewPanels.alchemy);
    }
  }
}

Future<void> _onInteractCharacter(dynamic character) async {
  if (character['entityType'] != 'character') {
    assert(character['entityType'] == 'npc',
        'invalid character entity type, ${character['entityType']}');
    final location = GameData.getLocation(character['atLocationId']);
    _onInteractNpc(character, location);
    return;
  }

  engine.debug('正在和角色 [${character['name']}] 互动。');

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
      (GameData.game['playerMonthly']['gifted'] as List).contains(character.id);
  final hasAttacked = (GameData.game['playerMonthly']['attacked'] as List)
      .contains(character.id);
  final hasStolen =
      (GameData.game['playerMonthly']['stolen'] as List).contains(character.id);
  if (!hasGifted) selections.add('gift');
  if (!hasAttacked) selections.add('attack');
  if (!hasStolen) selections.add('steal');
  selections.add('relationshipDiscourse');
  selections.add('bye');
  dialog.pushSelection(
    'characterInteraction',
    selections,
  );
  await dialog.execute();
  final selected = dialog.checkSelected('characterInteraction');

  bool interacted = false;
  switch (selected) {
    case 'characterInformation':
      showDialog(
        context: engine.context,
        builder: (context) => CharacterProfileView(
          character: character,
        ),
      );
    case 'talk':
      final topicSelections = [
        'journalTopic',
        'characterTopic',
        'organizationTopic',
        'locationTopic',
        'itemTopic',
        'cancel',
      ];
      dialog.pushSelection(
        'topicSelections',
        topicSelections,
      );
      await dialog.execute();
      final topic = dialog.checkSelected('topicSelections');
      switch (topic) {
        case 'journalsTopic':
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
          journalsSelections['cancel'] = engine.locale('cancel');
          dialog.pushSelectionRaw(
              {'id': 'journalSelections', 'selections': journalsSelections});
          await dialog.execute();
          final selectedJournalId = dialog.checkSelected('journalSelections');
          if (selectedJournalId == 'cancel') return;
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
            case 'organizationInitiation':
              if (character['organizationId'] ==
                  GameData.hero['organizationId']) {
                topicRejected = false;
                final organization =
                    GameData.game['organizations'][character['organizationId']];
                assert(organization != null,
                    'organization is null, id: ${character['organizationId']}');
                final memberData = organization['members'][GameData.hero['id']];
                assert(memberData != null,
                    'memberData is null, organization id: [${character['organizationId']}], character id: ${GameData.hero['id']}');
                final reportLocationId = memberData['reportLocationId'];
                final reportLocation =
                    GameData.game['locations'][reportLocationId];
                assert(reportLocation != null,
                    'Location is null, location id: $reportLocationId');
                final superiorId = memberData['superiorId'];
                final superior = GameData.getCharacter(superiorId);
                if (superiorId == character['id']) {
                  dialog.pushDialog(
                    'quest_organizationInitiation_topic_superior',
                    character: character,
                    interpolations: [
                      organization['name'],
                      reportLocation['name'],
                    ],
                  );
                  await dialog.execute();
                } else {
                  dialog.pushDialog(
                    'quest_organizationInitiation_topic',
                    character: character,
                    interpolations: [
                      organization['name'],
                      reportLocation['name'],
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
        case 'characterTopic':
          {}
        case 'organizationTopic':
          {}
        case 'locationTopic':
          {}
        case 'itemTopic':
          {}
      }
    case 'show':
      interacted = true;
      // 向角色展示某个物品
      final items = await GameLogic.showItemSelect(
          character: GameData.hero, multiSelect: false);
      final item = items.firstOrNull;
      if (item != null) {
        engine.debug('正在向 ${character['name']} 出示 ${item['name']}');
        engine.hetu.invoke('onGameEvent',
            positionalArgs: ['onShowItem', character, item]);
      }
    case 'gift':
      interacted = true;
      final items = await GameLogic.showItemSelect(
          character: GameData.hero, multiSelect: false);
      final item = items.first;
      if (item != null) {
        engine.debug('正在向 ${character.name} 赠送 ${item.name}');
        final result = await engine.hetu.invoke('onGameEvent',
            positionalArgs: ['onGiftItem', character, item]);
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
      interacted = true;
      // TODO:
      // 根据好感度决定折扣
      // 根据角色技能决定不同物品的折扣
      // 根据角色境界决定使用铜钱还是灵石交易
      double baseRate = kBaseBuyRate;
      final sellRateModifier =
          (bond['score'] * kPriceFavorRate) * kPriceFavorIncrement;
      baseRate -= sellRateModifier;
      if (baseRate < kMinBuyRate) {
        baseRate = kMinBuyRate;
      }
      double sellRate = kBaseSellRate;
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
            type: MerchantType.character,
          );
    case 'attack':
      interacted = true;
      {}
    case 'steal':
      interacted = true;
      {}
    case 'relationshipDiscourse':
      final relationshipSelections = [];

      /// 玩家角色并不能主动发起浪漫关系
      /// 只能有概率的被动触发 NPC 爱上自己的事件
      /// 只有对方爱上自己的情况下，才可以创建婚姻关系
      final bool isCharacterSpouse = engine.hetu
          .invoke('isSpouse', positionalArgs: [character, GameData.hero]);
      if (!isCharacterSpouse) {
        final bool isCharacterRomance = engine.hetu
            .invoke('isRomance', positionalArgs: [character, GameData.hero]);
        if (isCharacterRomance) {
          final bool hasProposed =
              (GameData.game['playerMonthly']['proposed'] as List)
                  .contains(character['id']);
          if (!hasProposed) {
            relationshipSelections.add('propose');
          }
        }
      } else {
        relationshipSelections.add('divorce');
      }

      // 师徒关系的传授功法
      final bool isCharacterShifu = engine.hetu
          .invoke('isTudi', positionalArgs: [character, GameData.hero]);
      final bool isCharacterTudi = engine.hetu
          .invoke('isTudi', positionalArgs: [GameData.hero, character]);
      // 不允许既是师父又是徒弟
      assert(!(isCharacterShifu && isCharacterTudi));
      final bool hasConsulted =
          GameData.game['playerMonthly']['consulted'].contains(character.id);
      final bool hasTutored =
          GameData.game['playerMonthly']['tutored'].contains(character.id);
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
          final bool hasBaishi =
              GameData.game['playerMonthly']['baishi'].contains(character.id);
          if (!hasBaishi) {
            relationshipSelections.add('baishi');
          }
        } else if (heroLevel > characterLevel && heroRank > characterRank) {
          final bool hasShoutu =
              GameData.game['playerMonthly']['shoutu'].contains(character.id);
          if (!hasShoutu) {
            relationshipSelections.add('shoutu');
          }
        }
      }

      // 组织的加入，招募和开除
      if (GameData.hero['organizationId'] == null) {
        final bool isCharacterHead = engine.hetu
            .invoke('isOrganizationHead', positionalArgs: [character]);
        final bool hasEnrolled = GameData.game['playerMonthly']['enrolled']
            .contains(character['organizationId']);
        if (isCharacterHead && !hasEnrolled) {
          relationshipSelections.add('enroll');
        }
      } else {
        final bool isHeroHead = engine.hetu
            .invoke('isOrganizationHead', positionalArgs: [GameData.hero]);
        final bool hasRecruited =
            GameData.game['playerMonthly']['recruited'].contains(character.id);
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

      switch (selected2) {
        case 'propose':
          interacted = true;
          {}
        case 'divorce':
          interacted = true;
          {}
        case 'consult':
          interacted = true;
          {}
        case 'tutor':
          interacted = true;
          {}
        case 'baishi':
          interacted = true;
          {}
        case 'shoutu':
          interacted = true;
          {}
        case 'apply':
          interacted = true;
          {}
        case 'recruit':
          interacted = true;
          {}
      }
  }

  if (interacted) {
    // 任何互动操作后，隐藏该角色不能再次互动
    engine.context.read<NpcListState>().hide(character['id']);
  }
}
