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
          (GameData.hero['stats']['lifeMax'] - GameData.hero['life']).floor() *
              kTicksPerTime;
    case 'cancel':
      return;
  }
  if (ticks <= 0) {
    GameDialogContent.show(
        engine.context, engine.locale('hint_alreadyFullHealthNoNeedRest'));
    return;
  }

  await TimeflowDialog.show(
    context: engine.context,
    ticks: ticks,
    onProgress: () {
      engine.hetu
          .invoke('restoreLife', namespace: 'Player', positionalArgs: [1]);
      engine.context.read<HeroState>().update();
      return GameData.hero['life'] >= GameData.hero['stats']['lifeMax'];
    },
  );

  engine.hetu.invoke('onGameEvent', positionalArgs: ['onRested']);
}

Future<void> _heroProduce(dynamic location, [dynamic npc]) async {
  final siteKind = location['kind'];
  assert(
      kProductionSiteKinds.contains(siteKind) &&
          kSiteWorkableBaseStaminaCost.containsKey(siteKind),
      '非可生产场所：${location['name']} ($siteKind)');

  final isRented = await _checkRented(location);
  if (!isRented) return;

  if (GameData.hero['life'] <= 1) {
    dialog.pushDialog(
      'hint_notEnoughStaminaToWork',
      npc: npc,
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

  // dialog.pushSelection('produceOption', [
  //   'produce5Days',
  //   'produce15Days',
  //   'produceTillNextMonth',
  //   'produceTillEmptyHealth',
  //   'cancel',
  // ]);
  // await dialog.execute();
  // final selected = dialog.checkSelected('produceOption');
  // if (selected == 'cancel') return;

  // int staminaCost = kSiteWorkableBaseStaminaCost[siteKind]!;
  // final double workStaminaCostFactor =
  //     GameData.hero['stats']['staminaCostWork'];
  // staminaCost = (staminaCost * workStaminaCostFactor).round();

  // int availableLife = (GameData.hero['life'] - 1).toInt();
  // if (availableLife <= staminaCost) {
  //   GameDialogContent.show(
  //       engine.context, engine.locale('hint_notEnoughStaminaToWork'));
  //   return;
  // }

  // int maxAffordableTicks = availableLife ~/ staminaCost;
  // int availableTicksTillNextMonth = kTicksPerMonth - GameLogic.ticksOfMonth;
  // final maxTicks = math.min(maxAffordableTicks, availableTicksTillNextMonth);

  // int ticks = 0;
  // switch (selected) {
  //   case 'produce5Days':
  //     ticks = kTicksPerDay * 5;
  //   case 'produce15Days':
  //     ticks = kTicksPerDay * 15;
  //   case 'produceTillNextMonth':
  //     ticks = availableTicksTillNextMonth;
  //   case 'produceTillEmptyHealth':
  //     ticks = maxAffordableTicks;
  // }
  // final finalTicks = math.min(ticks, maxTicks);
  // if (finalTicks <= 0) return;

  // await TimeflowDialog.show(
  //   context: engine.context,
  //   ticks: ticks,
  //   onProgress: () {
  //     final roll = GameData.random.nextDouble();
  //     for (String key in materialData.keys) {
  //       final double chance = materialData[key]!;
  //       if (roll <= chance) {
  //         final int abundance = resources[key] ?? 0;
  //         final int amount = (abundance ~/ kTicksPerDay);
  //         produced[key] = (produced[key] ?? 0) + amount;
  //       }
  //     }
  //     engine.hetu.invoke('setLife',
  //         namespace: 'Player',
  //         positionalArgs: [GameData.hero['life'] - staminaCost]);
  //     return GameData.hero['life'] <= staminaCost;
  //   },
  // );

  // engine.play('pickup_item-64282.mp3');
  // engine.hetu
  //     .invoke('collectAll', namespace: 'Player', positionalArgs: [produced]);
}

Future<void> _heroWork(dynamic location, [dynamic npc]) async {
  final siteKind = location['kind'];
  if (!kSiteKindsWorkable.contains(siteKind)) {
    engine.error('非可工作场所：${location['name']} ($siteKind)');
    return;
  }

  // 非门派成员，只能在一年中的指定时间打工
  // 门派成员则不受时间限制
  if (location['organizationId'] != null &&
      location['organizationId'] != GameData.hero['organizationId']) {
    final months = kSiteWorkableMounths[siteKind] as List;
    if (!months.contains(GameLogic.month)) {
      dialog.pushDialog(
        'hint_notWorkSeason',
        npc: npc,
        interpolations: [months.join(', ')],
      );
      await dialog.execute();
      return;
    }
  }

  if (GameData.hero['life'] <= 1) {
    dialog.pushDialog(
      'hint_notEnoughStaminaToWork',
      npc: npc,
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

  // final int salary = kSiteWorkableBaseSalaries[siteKind]!;
  // int staminaCost = kSiteWorkableBaseStaminaCost[siteKind]!;
  // final double workStaminaCostFactor =
  //     GameData.hero['stats']['staminaCostWork'];
  // staminaCost = (staminaCost * workStaminaCostFactor).round();

  // dialog.pushSelection('workOption', [
  //   'work10Days',
  //   'work30Days',
  //   'workTillNextMonth',
  //   'workTillHealthExhausted',
  //   'cancel',
  // ]);
  // await dialog.execute();
  // final selected = dialog.checkSelected('workOption');
  // int ticks = 0;
  // switch (selected) {
  //   case 'work10Days':
  //     ticks = kTicksPerDay * 10;
  //   case 'work30Days':
  //     ticks = kTicksPerDay * 30;
  //   case 'workTillNextMonth':
  //     ticks = kTicksPerMonth - GameLogic.ticksOfMonth;
  //   case 'workTillHealthExhausted':
  //     ticks = (GameData.hero['life'] - 1) ~/ staminaCost;
  // }
  // assert(ticks > 0);

  // final finalTicks = await TimeflowDialog.show(
  //   context: engine.context,
  //   ticks: ticks,
  //   onProgress: () {
  //     engine.hetu.invoke('setLife',
  //         namespace: 'Player',
  //         positionalArgs: [GameData.hero['life'] - staminaCost]);
  //     return GameData.hero['life'] <= staminaCost;
  //   },
  // );

  // engine.play('coins-31879.mp3');
  // engine.hetu.invoke('collect',
  //     namespace: 'Player', positionalArgs: ['money', finalTicks * salary]);
  // engine.context.read<HeroState>().update();
}

Future<void> _onInteractNpc(dynamic npc, dynamic location) async {
  engine.debug('正在和 NPC [${npc['name']}] 互动。');
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

  final heroId = GameData.hero['id'];
  final heroRank = GameData.hero['rank'];

  bool isManager = heroId == location['ownerId'];
  bool isMayor = heroId == atLocation?['ownerId'];
  bool isHead = heroId == organization?['headId'];

  bool hasAuthority = isManager || isMayor || isHead;

  final siteKind = location['kind'];
  if (siteKind == 'headquarters') {
    dialog.pushSelection(siteKind, [
      'organizationInformation',
      'relationshipDiscourse',
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
      case 'relationshipDiscourse':
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
            // 检查门派招募月份
            final recruitMonth = organization['recruitMonth'];
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
            if (GameData.checkMonthly(
                MonthlyActivityIds.enrolled, organization['id'])) {
              dialog.pushDialog(
                'hint_alreadyTrialedThisMonth',
                npc: npc,
              );
              return;
            }
            final organizationCategory = organization['category'];
            assert(kOrganizationCategories.contains(organizationCategory));
            dialog.pushDialog(
              'organization_${organizationCategory}_trial_intro',
              npc: npc,
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
                    'organization_${organizationCategory}_trial_pass',
                    npc: npc,
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
                  GameData.addHeroMonthly(
                      MonthlyActivityIds.enrolled, organization['id']);
                  dialog.pushDialog(
                    'organization_${organizationCategory}_trial_fail',
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
                  'generateDeck': false,
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
                engine.context.read<EnemyState>().show(enemy,
                    onBattleEnd: (bool battleResult, int roundCount) async {
                  if (roundCount <= kCultivationTrialMinBattleRound) {
                    dialog.pushDialog(
                      'organization_${organizationCategory}_trial_pass',
                      npc: npc,
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
                    GameData.addHeroMonthly(
                        MonthlyActivityIds.enrolled, organization['id']);
                    dialog.pushDialog(
                      'organization_${organizationCategory}_trial_fail',
                      npc: npc,
                    );
                    await dialog.execute();
                  }
                });
              case 'immortality':
                engine.hetu.invoke('resetTrial', namedArgs: {
                  'name': engine.locale('cultivation_trial'),
                  'difficulty': 0,
                  'organizationId': organization['id'],
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
                  // prebattlePreventClose: true,
                  onBattleEnd: (bool battleResult, int roundCount) async {
                    if (battleResult) {
                      dialog.pushDialog(
                        'organization_${organizationCategory}_trial_pass',
                        npc: npc,
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
                      GameData.addHeroMonthly(
                          MonthlyActivityIds.enrolled, organization['id']);
                      dialog.pushDialog(
                        'organization_${organizationCategory}_trial_fail',
                        npc: npc,
                      );
                      await dialog.execute();
                    }
                  },
                );
              case 'entrepreneur':
                final Iterable membersData = organization['membersData'].values;
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
                  // prebattlePreventClose: true,
                  onBattleEnd: (bool battleResult, int roundCount) async {
                    if (battleResult) {
                      dialog.pushDialog(
                        'organization_${organizationCategory}_trial_pass',
                        npc: npc,
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
                      GameData.addHeroMonthly(
                          MonthlyActivityIds.enrolled, organization['id']);
                      dialog.pushDialog(
                        'organization_${organizationCategory}_trial_fail',
                        npc: npc,
                      );
                      await dialog.execute();
                    }
                  },
                );
              case 'wealth':
                final int cost = kWealthTrialCost;
                dialog.pushSelectionRaw({
                  'id': 'organization_wealth_trial',
                  'selections': {
                    'pay_shard':
                        engine.locale('pay_shard', interpolations: [cost]),
                    'forgetIt': engine.locale('forgetIt'),
                  }
                });
                await dialog.execute();
                final selected =
                    dialog.checkSelected('organization_wealth_trial');
                if (selected == 'pay_shard') {
                  final int shard = GameData.hero['materials']['shard'] ?? 0;
                  if (shard >= cost) {
                    engine.hetu.invoke(
                      'exhaust',
                      namespace: 'Player',
                      positionalArgs: ['shard', cost],
                    );
                    dialog.pushDialog(
                      'organization_${organizationCategory}_trial_pass',
                      npc: npc,
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
                    dialog.pushDialog(engine.locale('hint_notEnoughShard'));
                    dialog.pushDialog(
                      'organization_${organizationCategory}_trial_fail',
                      npc: npc,
                    );
                    await dialog.execute();
                  }
                }
              case 'pleasure':
                final heroCharisma = GameData.hero['stats']['charisma'];
                if (heroCharisma >= kPleasureTrialMinCharisma) {
                  dialog.pushDialog(
                    'organization_${organizationCategory}_trial_pass',
                    npc: npc,
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
                    npc: npc,
                  );
                  await dialog.execute();
                }
            }
          case 'resign':
            final memberData = organization['membersData'][heroId];
            final jobRank = memberData['rank'] ?? 0;
            if (jobRank >= 3) {
              dialog.pushDialog('organization_resign_1', npc: npc);
              await dialog.execute();
              final resignSelections = [
                'resign_confirm',
                'forgetIt',
              ];
              dialog.pushSelection('resign_selections', resignSelections);
              final selected = dialog.checkSelected('resign_selections');
              if (selected != 'resign_confirm') return;
            }
            dialog.pushDialog('organization_resign_confirm',
                interpolations: [organization['name']]);
            await dialog.execute();
            engine.hetu.invoke(
              'removeCharacterFromOrganization',
              positionalArgs: [GameData.hero],
            );
            dialog.pushDialog('hint_organization_resign',
                interpolations: [organization['name']]);
            await dialog.execute();
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
    if (siteKind == 'cityhall') {
      siteOptions.add('cityInformation');
      if (organization == null) {
        if (GameData.hero['organizationId'] == null) {
          siteOptions.add('createOrganization2');
        } else {
          siteOptions.add('recruitCity');
        }
        siteOptions.add('yourContributionHere');
      }
    } else {
      siteOptions.add('siteInformation');
    }

    if (kSiteKindsWorkable.contains(siteKind)) {
      siteOptions.add({
        'text': 'work',
        'description': 'hint_work_description',
      });
    }
    if (kProductionSiteKinds.contains(siteKind) &&
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
      siteOptions.add('bountyQuest');
    } else if (siteKind == 'tradinghouse' ||
        kProductionSiteKinds.contains(siteKind)) {
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
      case 'createOrganization2':
        final rankString =
            '<rank$kCreateOrganizationRequirementRank>${engine.locale('cultivationRank_$kCreateOrganizationRequirementRank')}</>';
        dialog.pushDialog('hint_createOrganization_intro',
            npc: npc,
            interpolations: [
              rankString,
              kCreateOrganizationRequirementMoney,
              kCreateOrganizationRequirementShard,
            ]);
        await dialog.execute();
        final orgOrgId = GameData.hero['organizationId'];
        if (orgOrgId != null) {
          final oldOrg = GameData.getOrganization(orgOrgId);
          dialog.pushDialog('hint_createOrganization_intro',
              npc: npc, interpolations: [oldOrg['name']]);
          await dialog.execute();
          return;
        }
        if (heroRank < kCreateOrganizationRequirementRank) {
          final heroRankString =
              '<rank$heroRank>${engine.locale('cultivationRank_$heroRank')}</>';
          dialog.pushDialog('hint_createOrganization_rankTooLow',
              npc: npc,
              interpolations: [
                heroRankString,
                rankString,
              ]);
          await dialog.execute();
          return;
        }
        final hasMoney = GameData.hero['materials']['money'];
        final hasShard = GameData.hero['materials']['shard'];
        if (hasMoney < kCreateOrganizationRequirementMoney ||
            hasShard < kCreateOrganizationRequirementShard) {
          dialog.pushDialog('hint_createOrganization_notEnoughMoneyOrShard',
              npc: npc,
              interpolations: [
                kCreateOrganizationRequirementMoney,
                kCreateOrganizationRequirementShard,
              ]);
          await dialog.execute();
          return;
        }
        engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
          'money',
          kCreateOrganizationRequirementMoney,
        ]);
        engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
          'shard',
          kCreateOrganizationRequirementShard,
        ]);
        String? name;
        while (name == null) {
          dialog.pushDialog('hint_createOrganization_success_1', npc: npc);
          await dialog.execute();
          name = await showDialog(
            context: engine.context,
            builder: (context) => InputNameDialog(
              mode: InputNameMode.organization,
            ),
          );
        }
        String? category;
        while (category == null) {
          dialog.pushDialog('hint_createOrganization_success_2',
              npc: npc, interpolations: [name]);
          await dialog.execute();
          category = await GameLogic.selectFrom(kOrganizationCategories);
        }
        String? genre;
        while (genre == null) {
          dialog.pushDialog('hint_createOrganization_success_3',
              npc: npc, interpolations: [category, name]);
          await dialog.execute();
          genre = await GameLogic.selectFrom(kCultivationGenres);
        }
        dialog.pushDialog('hint_createOrganization_success_4',
            npc: npc, interpolations: [genre, name]);
        await dialog.execute();
        engine.hetu.invoke(
          'Organization',
          namedArgs: {
            'name': name,
            'category': category,
            'genre': genre,
            'headId': GameData.hero['id'],
            'headquartersLocation': atLocation,
          },
        );
      case 'recruitCity':
        final int development = location['development'];
        final developmentFactor = (development * 2 + 1);
        dialog.pushDialog('hint_createOrganization_intro',
            npc: npc,
            interpolations: [
              kRecruitCityRequirementContribution,
              kRecruitCityRequirementMoney,
              kRecruitCityRequirementShard,
            ]);
        await dialog.execute();
        final diplomacies = organization['diplomacies'];
        bool hasEnemy = false;
        for (final diplomacy in diplomacies.values) {
          if (diplomacy['type'] == 'enemy') {
            hasEnemy = true;
            break;
          }
        }
        if (hasEnemy) {
          dialog.pushDialog(
            'hint_recruitCity_atWar',
            npc: npc,
          );
          await dialog.execute();
          return;
        }
        final contribution = GameData.flags['contribution'][atLocation['id']];
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
        final requirementMoney =
            kRecruitCityRequirementMoney * developmentFactor;
        final requirementShard =
            kRecruitCityRequirementShard * developmentFactor;
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
        dialog
            .pushDialog('hint_recruitCity_success', npc: npc, interpolations: [
          atLocation['name'],
          organization['name'],
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
          'addLocationToOrganization',
          positionalArgs: [atLocation, organization],
        );
        engine.play('success-resolution-99782.mp3');
        if (heroId == organization['headId']) {
          atLocation['ownerId'] = heroId;
        } else {
          engine.hetu.invoke(
            'createJournalById',
            namespace: 'Player',
            positionalArgs: [
              'organizationRecruitCityReportToLeader',
            ],
            namedArgs: {
              'interpolations': [
                atLocation['name'],
                organization['name'],
              ],
            },
          );
        }
      case 'yourContributionHere':
        final contribution =
            location['contributions'][GameData.hero['id']] ?? 0;
        dialog.pushDialog('hint_yourContributionHere',
            npc: npc, interpolations: [contribution]);
        await dialog.execute();
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
        assert(atLocation != null,
            '试图查看 cityInformation 但 atLocation 为空, id: ${location['atLocationId']}');
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
        _heroProduce(location, npc);
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
          builder: (context) => QuestView(
            quests: bounties,
          ),
        );
        if (quest != null) {
          GameLogic.acquireQuest(quest, location, organization);
        }
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
            );
      case 'workbench':
        engine.context.read<ViewPanelState>().toogle(ViewPanels.workbench);
      case 'alchemy_furnace':
        engine.context.read<ViewPanelState>().toogle(ViewPanels.alchemy);
    }
  }
}

Future<void> _onInteractCharacter(dynamic character) async {
  if (character == GameData.hero) return;

  if (character['entityType'] != 'character') {
    assert(character['entityType'] == 'npc',
        'invalid character entity type, ${character['entityType']}');
    final location = engine.hetu.fetch('location');
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
      GameData.checkMonthly(MonthlyActivityIds.gifted, character.id);
  final hasAttacked =
      GameData.checkMonthly(MonthlyActivityIds.attacked, character.id);
  final hasStolen =
      GameData.checkMonthly(MonthlyActivityIds.stolen, character.id);
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
                final memberData =
                    organization['membersData'][GameData.hero['id']];
                assert(memberData != null,
                    'memberData is null, organization id: [${character['organizationId']}], character id: ${GameData.hero['id']}');
                final reportLocationId = memberData['reportLocationId'];
                final reportLocation = GameData.getLocation(reportLocationId);
                final superiorId = memberData['superiorId'];
                assert(superiorId != null,
                    'hero\'s superiorId is null, organization id: [${character['organizationId']}]');
                final superior = GameData.getCharacter(superiorId);
                if (superiorId == character['id']) {
                  dialog.pushDialog(
                    'topic_organizationInitiation_superior',
                    character: character,
                    interpolations: [
                      organization['name'],
                      reportLocation['name'],
                    ],
                  );
                  await dialog.execute();
                } else {
                  dialog.pushDialog(
                    'topic_organizationInitiation',
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
      final items = await GameLogic.selectItem(
          character: GameData.hero, multiSelect: false);
      final item = items.firstOrNull;
      if (item != null) {
        engine.debug('正在向 ${character['name']} 出示 ${item['name']}');
        engine.hetu
            .invoke('onGameEvent', positionalArgs: ['onShow', character, item]);
      }
    case 'gift':
      interacted = true;
      final items = await GameLogic.selectItem(
          character: GameData.hero, multiSelect: false);
      final item = items.first;
      if (item != null) {
        engine.debug('正在向 ${character.name} 赠送 ${item.name}');
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
            merchantType: MerchantType.character,
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
      final bool isCharacterShifu = engine.hetu
          .invoke('isTudi', positionalArgs: [character, GameData.hero]);
      final bool isCharacterTudi = engine.hetu
          .invoke('isTudi', positionalArgs: [GameData.hero, character]);
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
          final bool hasBaishi =
              GameData.checkMonthly(MonthlyActivityIds.baishi, character.id);
          if (!hasBaishi) {
            relationshipSelections.add('baishi');
          }
        } else if (heroLevel > characterLevel && heroRank > characterRank) {
          final bool hasShoutu =
              GameData.checkMonthly(MonthlyActivityIds.shoutu, character.id);
          if (!hasShoutu) {
            relationshipSelections.add('shoutu');
          }
        }
      }

      // 组织的加入，招募和开除
      if (GameData.hero['organizationId'] == null) {
        final bool isCharacterHead = engine.hetu
            .invoke('isOrganizationHead', positionalArgs: [character]);
        final bool hasEnrolled = GameData.checkMonthly(
            MonthlyActivityIds.enrolled, character['organizationId']);
        if (isCharacterHead && !hasEnrolled) {
          relationshipSelections.add('enroll');
        }
      } else {
        final bool isHeroHead = engine.hetu
            .invoke('isOrganizationHead', positionalArgs: [GameData.hero]);
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

  dialog.pushDialog(engine.locale('discourse_bye'), character: character);
  await dialog.execute();

  if (interacted) {
    // 任何互动操作后，隐藏该角色不能再次互动
    engine.context.read<NpcListState>().hide(character['id']);
  }
}
