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
import 'discard_zone.dart';
import 'energy_display.dart';
import 'hand_zone.dart';
import '../../global.dart';
import '../common.dart';
import '../../data/game.dart';
import '../../data/common.dart';
import 'common.dart';
import '../../state/states.dart';
import 'equipments_bar.dart';
import '../../widgets/character/profile.dart';

const kBattleRoundLimit = 16;

/// 后手方恢复 20% 战斗生命上限
const double kSecondHandHealRate = 0.2;

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

  late final SpriteComponent versusIcon;
  late final SpriteButton heroIcon, enemyIcon;
  late final EquipmentsBar heroEquipments, enemyEquipments;

  late final SpriteComponent2 victoryPrompt, defeatPrompt;

  late final BattleCharacter hero, enemy;
  late final BattleDeckZone heroDeckZone, enemyDeckZone;
  late final DiscardZone heroDiscardZone, enemyDiscardZone;
  late final HandZone heroHandZone, enemyHandZone;
  late final EnergyDisplay heroEnergyDisplay, enemyEnergyDisplay;
  late final SpriteButton endTurnButton;
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

  Completer<CustomGameCard?>? _playerCardSelection;
  bool _isPlayerTurnEnded = false;
  bool _isRestarting = false;

  int _replacedCardCount = 0;
  int _missingCardCount = 0;
  void showCharacterInfo(dynamic data) {
    showDialog(
      context: engine.context,
      builder: (context) {
        return CharacterProfileView(character: data);
      },
    );
  }

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

  List<CustomGameCard> getDeck(dynamic character, BattleDeckZone deck) {
    final List decks = character['battleDecks'];
    final index = character['battleDeckIndex'];
    if (decks.isNotEmpty && index >= 0 && index < decks.length) {
      final deckInfo = decks[index];
      final List cardIds = deckInfo['cards'];
      final bool isHero = identical(character, heroData);
      final List<CustomGameCard> cards = [];

      for (final id in cardIds) {
        final data = character['cardLibrary'][id];
        assert(data != null);
        if (isHero &&
            GameLogic.checkRequirements(data, checkIdentified: true) != null) {
          _replacedCardCount++;
          cards.add(_createBlankCard());
          continue;
        }
        final card = GameData.createBattleCard(data, deepCopyData: true);
        card.isFlipped = true;
        card.enableGesture = false;
        cards.add(card);
        world.add(card);
        deck.tryAddCard(card, sort: false, animated: false);
      }

      deck.sortCards();

      if (isHero) {
        _missingCardCount = math.max(0, kBattleDeckSize - cards.length);
        for (var i = 0; i < _missingCardCount; i++) {
          cards.add(_createBlankCard());
        }
      }

      return cards;
    } else {
      return [];
    }
  }

  CustomGameCard _createBlankCard() {
    final blankData = engine.hetu
        .invoke('BattleCard', namedArgs: {'affixId': 'blank_default'});
    final card = GameData.createBattleCard(blankData, deepCopyData: true);
    card.isFlipped = true;
    world.add(card);
    return card;
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

    Future.delayed(Duration(milliseconds: 250), () {
      _startBattle();
    });
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    engine.hetu.assign('enemy', enemyData);
    engine.hetu.assign('battleFlags', battleFlags);

    fps = FpsComponent();

    background = SpriteComponent2(
      spriteId: backgroundImageId,
      anchor: Anchor.center,
      position: center,
      size: size,
      boxFit: BoxFit.cover,
    );
    world.add(background);

    // 英雄头像：左上角
    heroIcon = SpriteButton(
      position: Vector2(GameUI.indent, GameUI.indent),
      spriteId: heroData['icon'],
      size: GameUI.battleCharacterAvatarSize,
      borderRadius: 12.0,
    );
    heroIcon.onTap = (_, __) {
      showCharacterInfo(heroData);
    };
    world.add(heroIcon);

    // 敌方头像：右上角
    enemyIcon = SpriteButton(
      position: Vector2(
          size.x - GameUI.battleCharacterAvatarSize.x - GameUI.indent,
          GameUI.indent),
      spriteId: enemyData['icon'],
      size: GameUI.battleCharacterAvatarSize,
      borderRadius: 12.0,
    );
    enemyIcon.onTap = (_, __) {
      showCharacterInfo(enemyData);
    };
    world.add(enemyIcon);

    // 英雄装备栏：头像右侧
    heroEquipments = EquipmentsBar(
      position: Vector2(
          GameUI.largeIndent +
              GameUI.battleCharacterAvatarSize.x +
              GameUI.smallIndent,
          GameUI.smallIndent +
              GameUI.battleCharacterAvatarSize.y / 2 -
              GameUI.equipmentsBarSize.y / 2),
      character: heroData,
    );
    world.add(heroEquipments);

    // 敌方装备栏：头像左侧
    enemyEquipments = EquipmentsBar(
      position: Vector2(
          size.x -
              GameUI.battleCharacterAvatarSize.x -
              GameUI.largeIndent -
              GameUI.smallIndent -
              GameUI.equipmentsBarSize.x,
          GameUI.smallIndent +
              GameUI.battleCharacterAvatarSize.y / 2 -
              GameUI.equipmentsBarSize.y / 2),
      character: enemyData,
    );
    world.add(enemyEquipments);

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
      reverseX: false,
      hovertipDirection: HovertipDirection.rightCenter,
    );
    world.add(heroDeckZone);

    heroDeck = getDeck(heroData, heroDeckZone);

    heroDiscardZone = DiscardZone(
      position: GameUI.p1BattleDiscardZonePosition,
      reverseX: false,
      hovertipDirection: HovertipDirection.rightCenter,
    );
    world.add(heroDiscardZone);

    heroEnergyDisplay = EnergyDisplay(
      position: GameUI.p1EnergyDisplayPosition,
    );
    camera.viewport.add(heroEnergyDisplay);

    // 英雄手牌区：屏幕左下方
    heroHandZone = HandZone(
      position: GameUI.p1HandZonePosition,
      enableInteraction: true,
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
      reverseX: true,
      hovertipDirection: HovertipDirection.leftCenter,
    );
    world.add(enemyDeckZone);

    enemyDeck = getDeck(enemyData, enemyDeckZone);

    enemyDiscardZone = DiscardZone(
      position: GameUI.p2BattleDiscardZonePosition,
      reverseX: true,
      hovertipDirection: HovertipDirection.leftCenter,
    );
    world.add(enemyDiscardZone);

    enemyEnergyDisplay = EnergyDisplay(
      position: GameUI.p2EnergyDisplayPosition,
    );
    camera.viewport.add(enemyEnergyDisplay);

    // 敌方手牌区：屏幕右下方
    enemyHandZone = HandZone(
      position: GameUI.p2HandZonePosition,
      reverseX: true,
      enableInteraction: false,
      pileStartPosition: Vector2(
        GameUI.p2HandZonePosition.x + GameUI.battleCardSize.x * 7,
        GameUI.p2HandZonePosition.y,
      ),
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

    endTurnButton = SpriteButton(
      spriteId: 'ui/button1.png',
      text: engine.locale('endTurn'),
      anchor: Anchor.center,
      position:
          Vector2(GameUI.indent + GameUI.buttonSizeIconLarge.width, size.y / 2),
      size: GameUI.buttonSizeIconLarge.toVector2(),
      isEnabled: false,
    );
    endTurnButton.onTap = (_, __) {
      endTurnButton.isEnabled = false;
      _isPlayerTurnEnded = true;

      for (final card in heroHandZone.cards) {
        heroHandZone.clearCardInteraction(card as CustomGameCard);
      }
    };
    camera.viewport.add(endTurnButton);

    // showStartPrompt();
  }

  // Future<void> showStartPrompt() async {
  // await charactersInformation.fadeIn(duration: 1.2);

  // }

  Future<void> _onBattleStart() async {
    battleStarted = true;
    battleEnded = false;
    battleResult = null;
    hero.reset();
    enemy.reset();
    // 将弃牌堆和手牌区的卡牌归还牌库
    _returnAllCardsToDecks();

    heroDeckZone.shuffle();
    enemyDeckZone.shuffle();

    hero.energy = 0;
    hero.turnCount = 0;
    enemy.energy = 0;
    enemy.turnCount = 0;

    heroEnergyDisplay.setEnergy(0);
    enemyEnergyDisplay.setEnergy(0);

    /// 根据身法加权随机决定先手，偷袭时英雄直接先手
    if (isSneakAttack) {
      isFirsthand = true;
    } else {
      final int heroDex = heroData['stats']['dexterity'];
      final int enemyDex = enemyData['stats']['dexterity'];
      // 每差 10 点身法，先手概率偏移 10%
      final double probability = (0.5 + (heroDex - enemyDex) / 100).clamp(0, 1);
      final roll = random.nextDouble();
      isFirsthand = roll < probability;
    }

    if (_replacedCardCount > 0 || _missingCardCount > 0) {
      if (_replacedCardCount > 0) {
        dialog.pushDialog('prebattle_card_invalid_replaced',
            interpolations: [_replacedCardCount]);
      }
      if (_missingCardCount > 0) {
        dialog.pushDialog('prebattle_card_empty_filled',
            interpolations: [_missingCardCount]);
      }
      await dialog.execute();
      _replacedCardCount = 0;
      _missingCardCount = 0;
    }

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
      final secondCharacter = heroTurn ? enemy : hero;
      final int overheal = secondCharacter.life -
          secondCharacter.data['stats']['lifeMax'] as int;
      final int heal =
          secondCharacter.lifeMax - secondCharacter.life + overheal;
      if (heal > 0) {
        secondCharacter.setLife(secondCharacter.lifeMax, overflow: true);
        secondCharacter.addHintText('${engine.locale('secondHandHeal')} +$heal',
            color: Colors.lightGreen);
      }
    }

    await onBattleStart?.call();
  }

  void _cleanupForRestart() {
    _returnAllCardsToDecks();
    heroHandZone.clearHand();
    enemyHandZone.clearHand();
    heroDeckZone.sortCards(animated: false);
    heroDeckZone.shuffle();
    enemyDeckZone.sortCards(animated: false);
    enemyDeckZone.shuffle();
    _isRestarting = false;
  }

  Future<void> _startBattle() async {
    while (battleResult == null) {
      if (_isRestarting) {
        _cleanupForRestart();
        battleStarted = false;
      }

      if (!battleStarted) {
        await _onBattleStart();
      }

      await _startTurn();
    }

    await _onBattleEnd();
  }

  void _returnAllCardsToDecks() {
    for (final zone in [heroDiscardZone, enemyDiscardZone]) {
      final deck = zone == heroDiscardZone ? heroDeckZone : enemyDeckZone;
      for (final card in zone.cards.toList()) {
        zone.removeCardByIndex(card.index);
        card.isFlipped = true;
        deck.cards.add(card);
        card.pile = deck;
      }
    }
    for (final hand in [heroHandZone, enemyHandZone]) {
      final deck = hand == heroHandZone ? heroDeckZone : enemyDeckZone;
      for (final card in hand.cards.toList()) {
        hand.clearCardInteraction(card as CustomGameCard);
        hand.cards.remove(card);
        card.isFlipped = true;
        deck.cards.add(card);
        card.pile = deck;
      }
      hand.cards.clear();
    }
  }

  void _shuffleDiscardIntoDeck(BattleDeckZone deck, DiscardZone discard) {
    for (final card in discard.cards.toList()) {
      deck.tryAddCard(card, sort: false);
    }
    deck.shuffle();
  }

  Future<int> drawCardsToHand(
    BattleDeckZone deck,
    DiscardZone discard,
    HandZone hand,
    int count,
  ) async {
    int drawn = 0;
    while (drawn < count) {
      if (deck.cards.isEmpty) {
        if (discard.cards.isEmpty) break;
        _shuffleDiscardIntoDeck(deck, discard);
      }
      final card = deck.cards.removeLast() as CustomGameCard;
      hand.tryAddCard(card, sort: false);
      drawn++;
    }
    await hand.sortCards(onComplete: () {
      if (hand == heroHandZone) {
        for (final card in hand.cards) {
          card.isFlipped = false;
        }
      }
    });
    return drawn;
  }

  void _onHeroCardSelected(CustomGameCard card) {
    if (_playerCardSelection != null && !_playerCardSelection!.isCompleted) {
      if (card.cost > currentCharacter.energy) return;
      _playerCardSelection!.complete(card);
      _playerCardSelection = null;
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
    final discardZone =
        currentCharacter.isHero ? heroDiscardZone : enemyDiscardZone;
    final handZone = currentCharacter.isHero ? heroHandZone : enemyHandZone;
    final energyDisplay =
        currentCharacter.isHero ? heroEnergyDisplay : enemyEnergyDisplay;

    if (roundCount > 0 && roundCount % kBattleRoundLimit == 0) {
      currentCharacter.addStatusEffect('energy_negative_life',
          amount: roundCount ~/ kBattleRoundLimit);
    }

    assert(deckZone.cards.isNotEmpty || discardZone.cards.isNotEmpty);

    do {
      currentCharacter.turnCount += 1;
      currentCharacter.energy = currentCharacter.energyMax;
      energyDisplay.setEnergy(currentCharacter.energy);

      final drawCount =
          GameLogic.getHandLimitForRank(currentCharacter.data['rank'])['limit']
              as int;
      final drawn =
          await drawCardsToHand(deckZone, discardZone, handZone, drawCount);

      await currentCharacter.onStartTurn(isExtra: extraTurn);

      extraTurn = false;

      bool skipTurn = false;
      if (drawn == 0 && handZone.cards.isEmpty) {
        skipTurn = true;
      } else if (currentCharacter.turnFlags['skipTurn'] == true) {
        skipTurn = true;
      }
      if (skipTurn) {
        break;
      }

      final opponentStatus =
          _prepareStatus(currentCharacter, StatusCircumstances.start_turn);
      for (final statusId in opponentStatus.keys) {
        final value = opponentStatus[statusId]!;
        currentOpponent.addStatusEffect(statusId,
            amount: value, handleCallback: false);
      }

      if (heroTurn) {
        endTurnButton.isEnabled = true;
        _isPlayerTurnEnded = false;
        while (!_isRestarting && !_isPlayerTurnEnded) {
          assert(_playerCardSelection == null);
          _playerCardSelection = Completer<CustomGameCard?>();
          final selectedCard = await _playerCardSelection!.future;
          if (selectedCard == null) break;

          currentCharacter.energy -= selectedCard.cost;
          handZone.energy = currentCharacter.energy;
          energyDisplay.setEnergy(currentCharacter.energy);
          handZone.clearCardInteraction(selectedCard);
          await currentCharacter.onUseCard(selectedCard);
          selectedCard.isFlipped = true;
          selectedCard.showGlow = false;
          discardZone.tryAddCard(selectedCard);
          selectedCard.pile = discardZone;
        }
      } else {
        while (!_isRestarting && currentCharacter.energy > 0) {
          final affordable = handZone.cards
              .where(
                  (c) => (c as CustomGameCard).cost <= currentCharacter.energy)
              .toList()
              .cast<CustomGameCard>();
          if (affordable.isEmpty) break;

          final selectedCard = _enemySelectCard(affordable);
          currentCharacter.energy -= selectedCard.cost;
          energyDisplay.setEnergy(currentCharacter.energy);

          selectedCard.isFlipped = false;
          await currentCharacter.onUseCard(selectedCard);
          handZone.clearCardInteraction(selectedCard);
          selectedCard.isFlipped = true;
          discardZone.tryAddCard(selectedCard);

          if (currentCharacter.turnFlags['extraTurn'] == true) {
            extraTurn = true;
          }
        }
      }

      if (_isRestarting) return;

      await currentCharacter.onEndTurn();

      final opponentEndStatus =
          _prepareStatus(currentCharacter, StatusCircumstances.end_turn);
      for (final statusId in opponentEndStatus.keys) {
        final value = opponentEndStatus[statusId]!;
        currentOpponent.addStatusEffect(statusId,
            amount: value, handleCallback: false);
      }

      for (final card in handZone.cards.toList()) {
        handZone.clearCardInteraction(card as CustomGameCard);
        card.isFlipped = true;
        discardZone.tryAddCard(card, sort: false);
      }
      handZone.clearHand();
      discardZone.sortCards(animated: false);
    } while (extraTurn);

    heroTurn = !heroTurn;
    currentCharacter = heroTurn ? hero : enemy;
    currentOpponent = heroTurn ? enemy : hero;

    if (currentCharacter == hero) {
      roundCount += 1;
    }

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
                width: GameUI.buttonSizeIconSmall.width,
                height: GameUI.buttonSizeIconSmall.height,
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
                          if (engine.config.developMode)
                            engine.locale('restart'): 'restart',
                          engine.locale('console'): 'console',
                          engine.locale('exit'): 'exit',
                        },
                        onSelectedItem: (String? item) async {
                          switch (item) {
                            case 'restart':
                              if (battleEnded) {
                                victoryPrompt.isVisible = false;
                                defeatPrompt.isVisible = false;
                                endButton.isVisible = false;
                                _startBattle();
                              } else if (battleStarted) {
                                _isRestarting = true;
                                _isPlayerTurnEnded = false;
                                if (_playerCardSelection != null &&
                                    !_playerCardSelection!.isCompleted) {
                                  _playerCardSelection!.complete(null);
                                  _playerCardSelection = null;
                                }
                              }
                            case 'console':
                              GameUI.showConsole(context);
                            case 'exit':
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
