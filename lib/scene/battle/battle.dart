import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:provider/provider.dart';
import 'package:samsara/components/ui/hovertip.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/widgets/ui/menu_builder.dart';
import 'package:samsara/hover_info.dart';

import '../../ui.dart';
import '../../logic/logic.dart';
import 'character.dart';
import 'battledeck_zone.dart';
import 'hand_zone.dart';
import '../../global.dart';
import 'character_information.dart';
import '../common.dart';
import '../../data/game.dart';
import 'common.dart';
import '../../state/states.dart';

const kMinTurnDuration = 800;
const kBattleRoundLimit = 16;

/// 后手方恢复 20% 战斗生命上限
const double kSecondHandHealRate = 0.2;

enum BattleMenuItems {
  console,
  exit,
}

/// 属性效果对应的永久状态，值是正面状态和负面状态的元组
const kStatsToPermanentEffects = {
  'unarmedAttack': ('enhance_unarmed', 'weaken_unarmed'),
  'weaponAttack': ('enhance_weapon', 'weaken_weapon'),
  'spellAttack': ('enhance_spell', 'weaken_spell'),
  'curseAttack': ('enhance_curse', 'weaken_curse'),
  'physicalResist': ('resistant_physical', 'weakness_physical'),
  'chiResist': ('resistant_chi', 'weakness_chi'),
  'elementalResist': ('resistant_elemental', 'weakness_elemental'),
  'psychicResist': ('resistant_psychic', 'weakness_psychic'),
};

const kSelfStatusOnCircumstance = {
  'defense_physical',
  'defense_chi',
  'defense_elemental',
  'defense_psychic',
  'speed_quick',
  'speed_nimble',
  'energy_positive_spell',
  'energy_positive_weapon',
  'energy_positive_unarmed',
  'energy_positive_life',
  'energy_positive_leech',
  'energy_positive_pure',
  'energy_positive_ultimate',
  'ward',
  'shield_physical',
  'shield_chi',
  'shield_elemental',
  'shield_psychic',
};

const kOpponentStatusOnCircumstance = {
  'weaken_unarmed',
  'weaken_weapon',
  'weaken_spell',
  'weaken_curse',
  'weakness_physical',
  'weakness_chi',
  'weakness_elemental',
  'weakness_psychic',
  'vulnerable_physical',
  'vulnerable_chi',
  'vulnerable_elemental',
  'vulnerable_psychic',
  'speed_slow',
  'speed_clumsy',
  'energy_negative_spell',
  'energy_negative_weapon',
  'energy_negative_unarmed',
  'energy_negative_life',
  'energy_negative_leech',
  'energy_negative_pure',
  'energy_negative_ultimate',
};

enum StatusCircumstances {
  start_battle,
  start_deck,
  start_turn,
  end_turn,
}

class BattleScene extends Scene {
  final menuController = fluent.FlyoutController();

  late FpsComponent fps;

  final String backgroundImageId;

  late final SpriteComponent2 background;
  late final SpriteComponent2 victoryPrompt, defeatPrompt;

  late final CharacterInformation charactersInformation;

  late final BattleCharacter hero, enemy;
  late final BattleDeckZone heroDeckZone, enemyDeckZone;
  late final HandZone heroHandZone, enemyHandZone;
  final dynamic heroData, enemyData;
  late final List<CustomGameCard> heroDeck, enemyDeck;

  final bool isSneakAttack;
  final bool isPractice;

  int roundCount = 0;

  /// 先手角色
  late bool isFirsthand;

  /// 当前是否是玩家回合
  late bool heroTurn;
  late BattleCharacter currentCharacter, currentOpponent;

  bool? battleResult;

  late final SpriteButton restartButton;
  // late final SpriteButton startButton;
  late final SpriteButton endButton;

  bool battleStarted = false;
  bool battleEnded = false;

  final Map<String, dynamic> battleFlags = {};

  FutureOr<void> Function()? onBattleStart;

  /// battleResult: true表示英雄胜利，false表示英雄失败，null表示战斗未结束
  /// roundCount: 战斗回合数（英雄每行动一次回合数加1）
  /// 如果返回值是 true, 则代表战斗结束逻辑中已经退出当前战斗场景，不会再重复退出
  FutureOr<dynamic> Function(bool result, int roundCount)? onBattleEnd;

  bool isDetailedHovertip = false;

  final int endBattleAfterRounds;

  Completer<CustomGameCard>? _playerCardSelection;
  bool _isRestarting = false;

  BattleScene({
    required this.heroData,
    required this.enemyData,
    required this.isSneakAttack,
    this.isPractice = false,
    this.onBattleStart,
    this.onBattleEnd,
    this.endBattleAfterRounds = 50,
    required this.backgroundImageId,
  }) : super(
          id: Scenes.battle,
          bgm: engine.bgm,
          bgmFile: 'war-drums-173853.mp3',
          bgmVolume: engine.config.musicVolume,
        );

  void _prepareBattleStart(BattleCharacter character) {
    for (final statName in kStatsToPermanentEffects.keys) {
      final (positiveEffectId, negativeEffectId) =
          kStatsToPermanentEffects[statName]!;

      final int value1 = character.data['stats'][statName];
      if (value1 > 0) {
        character.addStatusEffect(positiveEffectId,
            amount: value1, handleCallback: false);
      } else if (value1 < 0) {
        character.addStatusEffect(negativeEffectId,
            amount: -value1, handleCallback: false);
      }
    }

    final int karma = character.data['karma'];
    final int karmaMax = character.data['stats']['karmaMax'];
    if (karma > 0 && karmaMax > 0) {
      int karmaInBattle = math.min(karma, karmaMax);
      character.data['karma'] -= karmaInBattle;
      character.addStatusEffect('energy_positive_curse',
          amount: karmaInBattle, handleCallback: false);
    }

    if (character.data['passives']['enable_chakra'] != null) {
      character.addStatusEffect('enable_chakra',
          amount: 1, handleCallback: false);
    }

    if (character.data['passives']['enable_rage'] != null) {
      character.addStatusEffect('enable_rage',
          amount: 1, handleCallback: false);
    }

    // 灵力每 10 点: 战斗开始时获得 1 点灵气
    final int initialMana = character.data['stats']['spirituality'] ~/ 10;
    if (initialMana > 0) {
      character.addStatusEffect('energy_positive_spell',
          amount: initialMana, handleCallback: false);
    }
  }

  Map<String, int> _prepareStatus(
      BattleCharacter character, StatusCircumstances circumstance) {
    for (final statusId in kSelfStatusOnCircumstance) {
      final passiveId = '${circumstance.name}_with_$statusId';

      final passiveData = character.data['passives'][passiveId];
      if (passiveData != null) {
        int? value = passiveData['value'];
        if (value == null) {
          engine.warning('passiveData has no field `value`! $passiveData');
        }
        character.addStatusEffect(statusId,
            amount: value, handleCallback: false);
      }

      final ephemeralPassivesData =
          character.data['ephemeralPassives'][passiveId];
      if (ephemeralPassivesData != null) {
        int? value = ephemeralPassivesData['value'];
        if (value == null) {
          engine.warning(
              'ephemeralPassivesData has no field `value`! $ephemeralPassivesData');
        }
        character.addStatusEffect(statusId,
            amount: value, handleCallback: false);
      }
    }

    Map<String, int> opponentPrebattleStatus = {};
    for (final statusId in kOpponentStatusOnCircumstance) {
      final passiveId = '${circumstance.name}_with_opponent_$statusId';
      final passiveData = character.data['passives'][passiveId];
      if (passiveData != null) {
        int? value = passiveData['value'];
        if (value == null) {
          engine.warning('passiveData $passiveData has no field `value`!');
          value = 1;
        }
        opponentPrebattleStatus[statusId] = value;
      }
    }
    return opponentPrebattleStatus;
  }

  List<CustomGameCard> getDeck(dynamic character) {
    final List decks = character['battleDecks'];
    final index = character['battleDeckIndex'];
    if (decks.isNotEmpty && index >= 0 && index < decks.length) {
      final deckInfo = decks[index];
      final List cardIds = deckInfo['cards'];
      return cardIds.map((id) {
        final data = character['cardLibrary'][id];
        assert(data != null);
        final card = GameData.createBattleCard(data, deepCopyData: true);
        card.isFlipped = true;
        world.add(card);
        return card;
      }).toList();
    } else {
      return [];
    }
  }

  @override
  void onStart([dynamic arguments = const {}]) {
    super.onStart();

    engine.context.read<EnemyState>().setPrebattleVisible(false);
    engine.context.read<HoverContentState>().hide();
    engine.context.read<ViewPanelState>().clearAll();
  }

  @override
  void onMount() {
    super.onMount();

    Hovertip.hideAll();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    engine.hetu.assign('enemy', enemyData);
    engine.hetu.assign('battleFlags', battleFlags);

    fps = FpsComponent();

    heroDeck = getDeck(heroData);
    enemyDeck = getDeck(enemyData);

    background = SpriteComponent2(
      spriteId: backgroundImageId,
      anchor: Anchor.center,
      position: center,
      size: size,
      boxFit: BoxFit.cover,
    );
    world.add(background);

    victoryPrompt = SpriteComponent2(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/victory.png'),
      size: Vector2(480.0, 240.0),
      isVisible: false,
    );
    camera.viewport.add(victoryPrompt);
    defeatPrompt = SpriteComponent2(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/defeat.png'),
      size: Vector2(480.0, 240.0),
      isVisible: false,
    );
    camera.viewport.add(defeatPrompt);

    heroDeckZone = BattleDeckZone(
      position: GameUI.p1BattleDeckZonePosition,
      cards: heroDeck,
      focusedOffset: GameUI.battleCardFocusedOffset,
      reverseX: false,
      isVisible: false,
    );
    world.add(heroDeckZone);

    // 英雄手牌区：屏幕正下方
    heroHandZone = HandZone(
      position: Vector2((size.x - GameUI.handZoneSize.x) / 2,
          size.y - GameUI.handZoneSize.y - GameUI.indent),
      reverseX: false,
      isVisible: false,
    );
    heroHandZone.onCardSelected = _onHeroCardSelected;
    world.add(heroHandZone);

    final String heroSkinId = heroData['skin'];
    final String heroGenre = heroData['cultivationFavor'];
    final Set<String> heroAnimationStates = {};
    final Set<String> heroOverlayAnimationStates = {};
    for (final card in heroDeck) {
      final affixes = card.data['affixes'];
      for (final affix in affixes) {
        var startupRaw = affix['animation']?['startup'] ?? [];
        if (startupRaw is! List) {
          startupRaw = [startupRaw];
        }
        List<String> startup = List<String>.from(startupRaw);
        var recoveryRaw = affix['animation']?['recovery'] ?? [];
        if (recoveryRaw is! List) {
          recoveryRaw = [recoveryRaw];
        }
        List<String> recovery = List<String>.from(recoveryRaw);
        var actionsRaw = affix['animation']?['actions'] ?? [];
        if (actionsRaw is! List) {
          actionsRaw = [actionsRaw];
        }
        List<String> actions = List<String>.from(actionsRaw);
        var overlaysRaw = affix['animation']?['overlays'] ?? [];
        if (overlaysRaw is! List) {
          overlaysRaw = [overlaysRaw];
        }
        List<String> overlays = List<String>.from(overlaysRaw);
        heroAnimationStates.addAll(startup);
        heroAnimationStates.addAll(recovery);
        heroAnimationStates.addAll(actions);
        heroOverlayAnimationStates.addAll(overlays);
      }
    }
    heroAnimationStates.remove('');
    heroOverlayAnimationStates.remove('');
    hero = BattleCharacter(
      position: GameUI.p1CharacterAnimationPosition,
      size: GameUI.heroSpriteSize,
      isHero: true,
      skinId: '${heroSkinId}_$heroGenre',
      animationStates: heroAnimationStates,
      overlayAnimationStates: heroOverlayAnimationStates,
      data: heroData,
      deckZone: heroDeckZone,
    );
    world.add(hero);

    enemyDeckZone = BattleDeckZone(
      position: GameUI.p2BattleDeckZonePosition,
      cards: enemyDeck,
      focusedOffset: GameUI.battleCardFocusedOffset,
      reverseX: true,
      isVisible: false,
    );
    world.add(enemyDeckZone);

    // 敌方手牌区：屏幕正上方（牌库区下方）
    enemyHandZone = HandZone(
      position:
          Vector2((size.x - GameUI.handZoneSize.x) / 2, GameUI.enemyHandZoneY),
      reverseX: true,
      isVisible: false,
    );
    world.add(enemyHandZone);

    final String enemySkinId = enemyData['skin'];
    final String enemyGenre = enemyData['cultivationFavor'];
    final Set<String> enemyAnimationStates = {};
    final Set<String> enemyOverlayAnimationStates = {};
    for (final card in enemyDeck) {
      final affixes = card.data['affixes'];
      for (final affix in affixes) {
        var startupRaw = affix['animation']?['startup'] ?? [];
        if (startupRaw is! List) {
          startupRaw = [startupRaw];
        }
        List<String> startup = List<String>.from(startupRaw);
        var recoveryRaw = affix['animation']?['recovery'] ?? [];
        if (recoveryRaw is! List) {
          recoveryRaw = [recoveryRaw];
        }
        List<String> recovery = List<String>.from(recoveryRaw);
        var actionsRaw = affix['animation']?['actions'] ?? [];
        if (actionsRaw is! List) {
          actionsRaw = [actionsRaw];
        }
        List<String> actions = List<String>.from(actionsRaw);
        var overlaysRaw = affix['animation']?['overlays'] ?? [];
        if (overlaysRaw is! List) {
          overlaysRaw = [overlaysRaw];
        }
        List<String> overlays = List<String>.from(overlaysRaw);
        enemyAnimationStates.addAll(startup);
        enemyAnimationStates.addAll(recovery);
        enemyAnimationStates.addAll(actions);
        enemyOverlayAnimationStates.addAll(overlays);
      }
    }
    enemyAnimationStates.remove('');
    enemyOverlayAnimationStates.remove('');
    enemy = BattleCharacter(
      position: GameUI.p2CharacterAnimationPosition,
      size: GameUI.heroSpriteSize,
      skinId: '$enemySkinId${enemyGenre.isNotEmpty ? '_$enemyGenre' : ''}',
      animationStates: enemyAnimationStates,
      overlayAnimationStates: enemyOverlayAnimationStates,
      data: enemyData,
      deckZone: enemyDeckZone,
    );
    world.add(enemy);

    hero.opponent = enemy;
    enemy.opponent = hero;

    charactersInformation = CharacterInformation(
      position: Vector2(0, 0),
      hero: heroData,
      enemy: enemyData,
    );
    camera.viewport.add(charactersInformation);

    restartButton = SpriteButton(
      spriteId: 'ui/button2.png',
      text: engine.locale('start'),
      anchor: Anchor.center,
      position: Vector2(
          center.x, size.y - GameUI.buttonSizeMedium.y * 2 - GameUI.indent),
      size: GameUI.buttonSizeSmall,
      isVisible: true,
    );
    restartButton.onTap = (_, __) async {
      if (battleEnded) {
        // 战斗已结束：重置 UI，重新开始
        charactersInformation.showEquipments();
        heroDeckZone.isVisible = true;
        enemyDeckZone.isVisible = true;
        heroHandZone.isVisible = true;
        enemyHandZone.isVisible = true;

        victoryPrompt.isVisible = false;
        defeatPrompt.isVisible = false;
        endButton.isVisible = false;
        _startBattleFlow();
      } else if (battleStarted) {
        // 战斗中重启：设置标志位，解除等待中的 completer
        _isRestarting = true;
        if (_playerCardSelection != null &&
            !_playerCardSelection!.isCompleted) {
          _playerCardSelection!.complete(heroDeck.first);
        }
      } else {
        restartButton.text = engine.locale('restart');
        _startBattleFlow();
      }
    };
    camera.viewport.add(restartButton);

    endButton = SpriteButton(
      spriteId: 'ui/button1.png',
      text: engine.locale('end'),
      anchor: Anchor.center,
      position: Vector2(
          center.x, size.y - GameUI.buttonSizeMedium.y - GameUI.indent * 2),
      size: GameUI.buttonSizeSmall,
      isVisible: false,
    );
    endButton.onTap = (_, __) => _endScene();
    camera.viewport.add(endButton);

    _rollFirsthand();
    showStartPrompt();
  }

  Future<void> showStartPrompt() async {
    await charactersInformation.fadeIn(duration: 1.2);
  }

  /// 根据身法加权随机决定先手，偷袭时英雄直接先手
  void _rollFirsthand() {
    if (isSneakAttack) {
      isFirsthand = true;
      return;
    }
    final int heroDex = heroData['stats']['dexterity'];
    final int enemyDex = enemyData['stats']['dexterity'];
    // 每差 10 点身法，先手概率偏移 10%
    final double probability = (0.5 + (heroDex - enemyDex) / 100).clamp(0, 1);
    final roll = random.nextDouble();
    isFirsthand = roll < probability;
  }

  Future<void> _onBattleStart() async {
    battleStarted = true;
    battleEnded = false;
    battleResult = null;
    hero.reset();
    enemy.reset();
    heroDeckZone.shuffle();
    enemyDeckZone.shuffle();
    _rollFirsthand();

    _prepareBattleStart(hero);
    final enemyStatus = _prepareStatus(hero, StatusCircumstances.start_battle);
    for (final statusId in enemyStatus.keys) {
      final value = enemyStatus[statusId]!;
      enemy.addStatusEffect(statusId, amount: value, handleCallback: false);
    }

    _prepareBattleStart(enemy);
    final heroStatus = _prepareStatus(enemy, StatusCircumstances.start_battle);
    for (final statusId in heroStatus.keys) {
      final value = heroStatus[statusId]!;
      hero.addStatusEffect(statusId, amount: value, handleCallback: false);
    }

    heroTurn = isFirsthand;
    currentCharacter = heroTurn ? hero : enemy;
    currentOpponent = heroTurn ? enemy : hero;
    currentCharacter.addHintText('${engine.locale('attackFirstInBattle')}!');

    // 后手补偿: 恢复少量生命（偷袭时无补偿）
    if (!isSneakAttack) {
      final secondHandCharacter = heroTurn ? enemy : hero;
      final int overheal = secondHandCharacter.life -
          secondHandCharacter.data['stats']['lifeMax'] as int;
      final int heal =
          secondHandCharacter.lifeMax - secondHandCharacter.life + overheal;
      if (heal > 0) {
        secondHandCharacter.setLife(secondHandCharacter.lifeMax,
            overflow: true);
        secondHandCharacter.addHintText(
            '${engine.locale('secondHandHeal')} +$heal',
            color: Colors.lightGreen);
      }
    }

    await onBattleStart?.call();
  }

  Future<void> _startBattleFlow() async {
    while (true) {
      _isRestarting = false;
      await _onBattleStart();

      while (battleResult == null && !_isRestarting) {
        await _startTurn();
      }

      if (_isRestarting) {
        await _cleanupForRestart();
        continue;
      }

      await _onBattleEnd();
      break;
    }
  }

  Future<void> _cleanupForRestart() async {
    // 将手牌区中的所有卡牌归还到各自的牌库区，然后清空手牌
    if (heroHandZone.cards.isNotEmpty) {
      await _returnCardsToDeck(heroHandZone, heroDeckZone);
    }
    await heroHandZone.clearHand();
    if (enemyHandZone.cards.isNotEmpty) {
      await _returnCardsToDeck(enemyHandZone, enemyDeckZone);
    }
    await enemyHandZone.clearHand();
  }

  /// 从牌库抽取指定数量的卡牌到指定手牌区
  List<CustomGameCard> _drawCards(
      BattleDeckZone deckZone, HandZone handZone, int count) {
    final actualCount = math.min(count, deckZone.cards.length);
    final drawn = <CustomGameCard>[];
    for (var i = 0; i < actualCount; i++) {
      final card = deckZone.cards.removeLast() as CustomGameCard;
      card.isFlipped = false;
      drawn.add(card);
    }
    deckZone.sortCards(animated: false);
    return drawn;
  }

  /// 将手牌放回牌库并洗牌
  Future<void> _returnCardsToDeck(
      HandZone handZone, BattleDeckZone deckZone) async {
    for (final card in handZone.cards.toList()) {
      handZone.clearCardInteraction(card as CustomGameCard);
      handZone.cards.remove(card);

      deckZone.cards.add(card);
      card.pile = deckZone;
    }
    await deckZone.sortCards(animated: true);
    deckZone.shuffle();
  }

  /// 将手牌区的牌加入并播放动画
  Future<void> _addCardsToHand(
      HandZone handZone, List<CustomGameCard> cards) async {
    for (final card in cards) {
      handZone.cards.add(card);
      card.pile = handZone;
      handZone.setupCardInteraction(card);
    }
    await handZone.sortCards();
  }

  void _onHeroCardSelected(CustomGameCard card) {
    if (_playerCardSelection != null && !_playerCardSelection!.isCompleted) {
      _playerCardSelection!.complete(card);
    }
  }

  /// 敌方简单AI：血量<50%优先buff，否则优先attack
  CustomGameCard _enemySelectCard(List<CustomGameCard> hand) {
    final buffs = hand.where((c) {
      final affix = c.data['affixes'][0];
      return affix['category'] == 'buff';
    }).toList();
    final attacks = hand.where((c) {
      final affix = c.data['affixes'][0];
      return affix['category'] == 'attack';
    }).toList();

    if (currentCharacter.life < currentCharacter.lifeMax * 0.5 &&
        buffs.isNotEmpty) {
      return buffs[engine.random.nextInt(buffs.length)];
    }
    if (attacks.isNotEmpty) {
      return attacks[engine.random.nextInt(attacks.length)];
    }
    return hand[engine.random.nextInt(hand.length)];
  }

  Future<void> _startTurn() async {
    bool extraTurn = false;

    engine.hetu.assign('self', currentCharacter);
    engine.hetu.assign('opponent', currentOpponent);

    currentCharacter.priority = kTopLayerAnimationPriority;
    currentOpponent.priority = 0;

    final deckZone = currentCharacter.deckZone;
    final handZone = currentCharacter == hero ? heroHandZone : enemyHandZone;

    // 死亡debuff：与回合数绑定，每 kBattleRoundLimit 回合触发
    if (roundCount > 0 && roundCount % kBattleRoundLimit == 0) {
      currentCharacter.addStatusEffect('energy_negative_life',
          amount: roundCount ~/ kBattleRoundLimit);
    }

    if (deckZone.cards.isNotEmpty) {
      do {
        // 回合开始状态效果
        final opponentStatus =
            _prepareStatus(currentCharacter, StatusCircumstances.start_turn);
        for (final statusId in opponentStatus.keys) {
          final value = opponentStatus[statusId]!;
          currentOpponent.addStatusEffect(statusId,
              amount: value, handleCallback: false);
        }

        // 抽牌
        final drawCount = GameLogic.getHandLimitForRank(
            currentCharacter.data['rank'])['limit'] as int;
        final drawnCards = _drawCards(deckZone, handZone, drawCount);

        if (drawnCards.isEmpty) {
          break;
        }

        await _addCardsToHand(handZone, drawnCards);

        // 选择卡牌
        CustomGameCard selectedCard;
        if (currentCharacter == hero) {
          _playerCardSelection = Completer<CustomGameCard>();
          selectedCard = await _playerCardSelection!.future;
          _playerCardSelection = null;
          if (_isRestarting) return;
        } else {
          await Future.delayed(Duration(milliseconds: 600));
          selectedCard = _enemySelectCard(drawnCards);
        }

        // 禁用所有手牌交互
        for (final card in handZone.cards) {
          handZone.clearCardInteraction(card as CustomGameCard);
        }

        // 执行选中卡牌的效果
        final turnDetails = await currentCharacter.onTurnStart(selectedCard,
            isExtra: extraTurn);

        final skipTurn = turnDetails['skipTurn'] ?? false;
        if (!skipTurn) {
          final turnEndDetails = await currentCharacter.onTurnEnd(selectedCard);
          extraTurn = turnEndDetails['extraTurn'] ?? false;

          final opponentEndStatus =
              _prepareStatus(currentCharacter, StatusCircumstances.end_turn);
          for (final statusId in opponentEndStatus.keys) {
            final value = opponentEndStatus[statusId]!;
            currentOpponent.addStatusEffect(statusId,
                amount: value, handleCallback: false);
          }
        }

        // 将所有手牌（包括打出的）放回牌库并洗牌
        await _returnCardsToDeck(handZone, deckZone);
        await handZone.clearHand();
      } while (extraTurn);
    }

    heroTurn = !heroTurn;
    currentCharacter = heroTurn ? hero : enemy;
    currentOpponent = heroTurn ? enemy : hero;

    if (currentCharacter == hero) {
      roundCount += 1;
    }

    // 检查战斗是否结束
    if (enemy.life <= 0) {
      battleResult = true;
    } else if (hero.life <= 0) {
      battleResult = false;
    } else if (endBattleAfterRounds > 0 && roundCount >= endBattleAfterRounds) {
      if (hero.life > enemy.life) {
        battleResult = true;
      } else {
        battleResult = false;
      }
    }
  }

  void _endScene() async {
    if (!isPractice) {
      engine.hetu
          .invoke('setCharacterLife', positionalArgs: [hero.data, hero.life]);
    }
    if (battleResult == false) {
      gameState.isInteractable = false;
    }
    engine.context.read<EnemyState>().clear();
    engine.hetu.assign('enemy', null);
    engine.hetu.assign('self', null);
    engine.hetu.assign('opponent', null);
    engine.hetu.assign('battleFlags', null);
    await onBattleEnd?.call(battleResult ?? false, roundCount);
    if (engine.scene?.id == Scenes.battle) {
      engine.popScene(clearCache: true);
    }
  }

  void clearEphemeralPassives(BattleCharacter character) {
    final ephemeralPassives = character.data['ephemeralPassives'];
    final toBeRemovedEphemeralPassives = [];
    for (final passiveId in ephemeralPassives.keys) {
      if (ephemeralPassives[passiveId]['isPermanent'] != true) {
        toBeRemovedEphemeralPassives.add(passiveId);
      }
    }
    for (final passiveId in toBeRemovedEphemeralPassives) {
      ephemeralPassives.remove(passiveId);
    }
    engine.hetu
        .invoke('characterCalculateStats', positionalArgs: [character.data]);
  }

  Future<void> _onBattleEnd() async {
    battleEnded = true;
    endButton.isVisible = true;

    if (battleResult == true) {
      victoryPrompt.isVisible = true;
      enemy.setState(kDefeatState);

      if (!isPractice) {
        // 如果开启了煞气天赋，战胜对手后增加 5 点煞气
        if (heroData['passives']['enable_karma'] != null) {
          heroData['karma'] += 5;
        }
      }
    } else {
      battleResult = false;
      defeatPrompt.isVisible = true;
      hero.setState(kDefeatState);
    }

    final heroName = '${hero.data['name']}(hero)';
    final enemyName = '${enemy.data['name']}(enemy)';
    engine.info(
        '$heroName和$enemyName结束了战斗。${battleResult! ? heroName : enemyName}获胜！');

    if (!isPractice) {
      clearEphemeralPassives(hero);
      clearEphemeralPassives(enemy);

      bool hasScroll = false;
      for (final card in heroDeck) {
        if (card.data['isEphemeral'] == true) {
          hasScroll = true;
          engine.hetu.invoke('dismantleCard',
              namespace: 'Player',
              positionalArgs: [card.data],
              namedArgs: {'gainFragments': false});
        }
      }
      if (hasScroll) {
        engine.clearCachedScene(Scenes.library);
      }
    }

    final hpRestoreRate = GameLogic.getHPRestoreRateAfterBattle(roundCount);
    final int life = hero.life;
    if (!isPractice) {
      if (battleResult == true) {
        final replenish = (hero.lifeMax * hpRestoreRate).round();
        engine.info('战斗结果: [$battleResult], 角色生命恢复: $replenish');
        final int newLife = life + replenish;
        hero.setLife(newLife);
      } else {
        if (life <= 0) {
          hero.setLife(1);
        } else if (life > hero.lifeMax) {
          hero.setLife(hero.lifeMax);
        }
      }
    }
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Stack(
      children: [
        SceneWidget(
          scene: this,
          loadingBuilder: loadingBuilder,
          overlayBuilderMap: overlayBuilderMap,
          initialActiveOverlays: initialActiveOverlays,
        ),
        GameUIOverlay(
          showHero: false,
          showNpcs: false,
          actions: [
            if (engine.config.developMode)
              Container(
                decoration: GameUI.boxDecoration,
                width: GameUI.infoButtonSize.width,
                height: GameUI.infoButtonSize.height,
                child: fluent.FlyoutTarget(
                  controller: menuController,
                  child: IconButton(
                    icon: Icon(Icons.menu_open),
                    padding: const EdgeInsets.all(0),
                    mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
                    onPressed: () {
                      showFluentMenu(
                        cursor: GameUI.cursor,
                        controller: menuController,
                        items: {
                          engine.locale('console'): BattleMenuItems.console,
                          engine.locale('exit'): BattleMenuItems.exit,
                        },
                        onSelectedItem: (item) {
                          switch (item) {
                            case BattleMenuItems.console:
                              GameUI.showConsole(context);
                            case BattleMenuItems.exit:
                              _endScene();
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);
  }
}
