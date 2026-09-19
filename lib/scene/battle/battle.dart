import 'dart:async';
import 'dart:collection';
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
import 'card_shatter.dart';
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

const kBattleRoundLimit = 8;

/// 属性效果对应的永久状态，值是正面状态和负面状态的元组
const kStatsToPermanentEffects = {
  'unarmedAttack': ('enhance_unarmed', 'weaken_unarmed'),
  'weaponAttack': ('enhance_weapon', 'weaken_weapon'),
  'spellAttack': ('enhance_spell', 'weaken_spell'),
  'curseAttack': ('enhance_curse', 'weaken_curse'),
  'fireResist': ('resistant_fire', 'weakness_fire'),
  'iceResist': ('resistant_ice', 'weakness_ice'),
  'lightningResist': ('resistant_lightning', 'weakness_lightning'),
  'poisonResist': ('resistant_poison', 'weakness_poison'),
};

/// 无反面效果的纯增益属性 → 同名永久状态（在 _prepareBattleStart 中单独处理，
/// 各流派伤害增加 increase_damage_* 以状态数据为准动态匹配，不在此列出）
const _kPositiveOnlyStatsToPermanentEffects = ['persistent', 'penetration'];

const kStatusOnCircumstance = {
  'defense',
  'weaken_unarmed',
  'weaken_weapon',
  'weaken_spell',
  'weaken_curse',
  'weakness_fire',
  'weakness_ice',
  'weakness_lightning',
  'weakness_poison',
  'vulnerable',
  'speed_quick',
  'dodge_nimble',
  'speed_slow',
  'dodge_clumsy',
  'buff_crit',
  'buff_ward',
  'buff_shield',
  'debuff_crit',
  'debuff_ward',
  'debuff_shield',
  'energy_positive_life',
  'energy_positive_spell',
  'energy_positive_weapon',
  'energy_positive_unarmed',
  'energy_positive_ultimate',
  'energy_negative_life',
  'energy_negative_spell',
  'energy_negative_weapon',
  'energy_negative_unarmed',
  'energy_negative_curse',
  'energy_negative_ultimate',
};

enum StatusCircumstances {
  start_battle,
  start_turn,
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

  // 队列模式：移除旧的 Completer
  // Completer<CustomGameCard?>? _playerCardSelection;

  // 待打出队列
  final Queue<CustomGameCard> _cardQueue = Queue();

  // 队列处理状态锁
  bool _isProcessingQueue = false;

  // 结束回合标志
  bool _endPlayerTurn = false;

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
      } else if (value1 < 0 && negativeEffectId.isNotEmpty) {
        character.addStatusEffect(negativeEffectId,
            amount: -value1, handleCallback: false);
      }
    }

    // 无反面效果的纯增益属性（护甲保持/护甲穿透/各流派伤害增加）：
    // 不放入 kStatsToPermanentEffects，单独转换为同名永久状态图标（图标即真值）
    for (final statName in _kPositiveOnlyStatsToPermanentEffects) {
      final value = character.data['stats'][statName];
      if (value is num && value > 0) {
        character.addStatusEffect(statName,
            amount: value.toInt(), handleCallback: false);
      }
    }
    // 各流派伤害增加：以状态数据为准（increase_damage_ 前缀），stats 中的同名属性转换为永久图标
    for (final statusId in GameData.statusEffects.keys) {
      if (!statusId.startsWith('increase_damage_')) continue;
      final value = character.data['stats'][statusId];
      if (value is num && value > 0) {
        character.addStatusEffect(statusId,
            amount: value.toInt(), handleCallback: false);
      }
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
    for (final statusId in kStatusOnCircumstance) {
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
    for (final statusId in kStatusOnCircumstance) {
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

  Future<List<CustomGameCard>> getDeck(dynamic character, BattleDeckZone deck,
      {bool isHero = false}) async {
    final List decks = character['battleDecks'];
    final index = character['battleDeckIndex'];
    if (decks.isNotEmpty && index >= 0 && index < decks.length) {
      final deckInfo = decks[index];
      final List cardIds = deckInfo['cards'];
      final List<CustomGameCard> cards = [];

      for (final id in cardIds) {
        final data = character['cardLibrary'][id];
        assert(data != null);
        // 次数耗尽的符箓（chargeData.current <= 0）与其他无效卡一样替换为默认卡
        final chargeData = data['chargeData'];
        final chargeExhausted =
            chargeData != null && (chargeData['current'] as num) <= 0;
        if (isHero &&
            (GameLogic.checkRequirements(data, checkLevel: false) != null ||
                chargeExhausted)) {
          _replacedCardCount++;
          cards.add(_createBlankCard());
          continue;
        }
        final card = GameData.createBattleCard(data, deepCopyData: true);
        card.isFlipped = true;
        card.enableGesture = false;
        cards.add(card);
        world.add(card);
        deck.tryAddCard(card);
      }

      await deck.sortCards(animated: false);

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

    heroDeck = await getDeck(heroData, heroDeckZone, isHero: true);

    heroDiscardZone = DiscardZone(
      position: GameUI.p1BattleDiscardZonePosition,
      reverseX: false,
      hovertipDirection: HovertipDirection.rightCenter,
    );
    world.add(heroDiscardZone);

    heroEnergyDisplay = EnergyDisplay(
      position: GameUI.p1QiBarPosition,
      isHero: true,
    );
    camera.viewport.add(heroEnergyDisplay);

    // 英雄手牌区：屏幕左下方
    heroHandZone = HandZone(
      position: GameUI.p1HandZonePosition,
      enableInteraction: true,
    );
    heroHandZone.onCardSelected = onPlayerSelectedCard;
    // 置灰卡牌的悬浮提示附加缺少资源信息（§6.2；可支付的卡牌缺失列表为空，原样展示）
    heroHandZone.onHoverDescription = (card, description) {
      if (_cardQueue.contains(card)) return description;
      final missing = _missingCostReport(card);
      if (missing.isNotEmpty) {
        return '<red>$missing</>\n$description';
      }
      return description;
    };
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
      isHero: true,
      position: GameUI.p1CharacterAnimationPosition,
      size: GameUI.heroSpriteSize,
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

    enemyDeck = await getDeck(enemyData, enemyDeckZone);

    enemyDiscardZone = DiscardZone(
      position: GameUI.p2BattleDiscardZonePosition,
      reverseX: true,
      hovertipDirection: HovertipDirection.leftCenter,
    );
    world.add(enemyDiscardZone);

    enemyEnergyDisplay = EnergyDisplay(
      position: GameUI.p2QiBarPosition,
      isHero: false,
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
      isHero: false,
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
      spriteId: 'ui/icon1.png',
      text: engine.locale('endTurn'),
      textConfig: ScreenTextConfig(anchor: Anchor.center),
      anchor: Anchor.center,
      position: Vector2(
          GameUI.indent + GameUI.buttonSizeIconLarge.width / 2, size.y / 2),
      size: GameUI.buttonSizeIconLarge.toVector2(),
      isEnabled: false,
    );
    endTurnButton.onTap = (_, __) {
      if (battleEnded) return;
      endTurnButton.isEnabled = false;
      onPlayerSelectedCard(null);
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

    hero.turnCount = 0;
    enemy.turnCount = 0;

    heroEnergyDisplay.refresh(hero);
    enemyEnergyDisplay.refresh(enemy);

    // 将弃牌堆和手牌区的卡牌归还牌库
    await _returnAllCardsToDecks();

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

    // 后手补偿：恢复到当前战斗生命上限（偷袭时无补偿）
    if (!isSneakAttack) {
      final secondCharacter = heroTurn ? enemy : hero;
      final int heal = secondCharacter.lifeMax - secondCharacter.life;
      if (heal > 0) {
        secondCharacter.setLife(secondCharacter.lifeMax);
        secondCharacter.addHintText('${engine.locale('secondHandHeal')} +$heal',
            color: Colors.lightGreen);
      }
    }

    await onBattleStart?.call();

    refreshHandCardDescriptions();
  }

  Future<void> clearHand(HandZone hand, DiscardZone discard,
      {bool animated = true}) async {
    for (final card in hand.cards.reversed.toList()) {
      card.isFlipped = true;
      card.clearInteraction();
      discard.tryAddCard(card);
    }
    await discard.sortCards(animated: animated);
    return;
  }

  Future<void> _startBattle() async {
    while (battleResult == null) {
      if (_isRestarting) {
        // 清理队列和状态
        _cardQueue.clear();
        _isProcessingQueue = false;
        _endPlayerTurn = false;

        await _returnAllCardsToDecks();
        _isRestarting = false;
        battleStarted = false;
      }

      if (!battleStarted) {
        await _onBattleStart();
      }

      await _startTurn();
    }

    await _onBattleEnd();
  }

  Future<void> _returnAllCardsToDecks() async {
    await clearHand(heroHandZone, heroDiscardZone, animated: false);
    await clearHand(enemyHandZone, enemyDiscardZone, animated: false);
    await shuffleDiscardIntoDeck(heroDeckZone, heroDiscardZone,
        animated: false);
    await shuffleDiscardIntoDeck(enemyDeckZone, enemyDiscardZone,
        animated: false);
  }

  Future<void> shuffleDiscardIntoDeck(BattleDeckZone deck, DiscardZone discard,
      {bool animated = true}) async {
    for (final card in discard.cards.toList()) {
      deck.tryAddCard(card);
    }
    deck.shuffle();
    await deck.sortCards(animated: animated);
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
        await shuffleDiscardIntoDeck(deck, discard);
      }
      hand.tryAddCard(deck.cards.last, sort: true);
      drawn++;
    }
    if (hand == heroHandZone) {
      for (final card in hand.cards) {
        card.isFlipped = false;
      }
    }
    await hand.sortCards();
    if (hand == heroHandZone) {
      refreshHandCardDescriptions();
    }
    return drawn;
  }

  /// 刷新英雄手牌所有卡牌的卡面描述：
  /// 逐词条计算伤害预测值并写入词条数据（原始 value 不动），
  /// 预测值与原值的比较着色由 getBattleCardDescription(withPrediction) 完成
  void refreshHandCardDescriptions() {
    for (final card in heroHandZone.cards) {
      final cardData = (card as CustomGameCard).data;
      for (final affix in cardData['affixes']) {
        // 英雄手牌的攻击目标是敌方，预测以敌方为防守方计算
        final predicted = enemy.predictDamage(hero, affix);
        affix['predictedValue'] = predicted?.$1;
        affix['predictedCrit'] = predicted?.$2;
        affix['predictedAilment'] = predicted?.$3;
      }
      final (description, _) = GameData.getBattleCardDescription(
        cardData,
        showRequirement: false,
        isDetailed: false,
        withPrediction: true,
      );
      card.description = description;
    }
  }

  /// 卡牌的有色费用（颜色 → 数量），无则空表
  Map<String, int> _cardCostColored(CustomGameCard card) {
    final qiCost = card.data['qiCost'];
    if (qiCost is Map) {
      return qiCost
          .map((key, value) => MapEntry('$key', (value as num).toInt()));
    }
    return const {};
  }

  /// 检查能否支付卡牌费用（全有或全无）。
  /// [queued] 为已入队待打出的卡牌，其费用与当前卡一并计入（入队时的资源预占）。
  /// 虚空之气（energy_negative_ultimate）每层使所有有色费用 +1，无上限（共识 5）。
  bool _canPayCardCost(BattleCharacter character, CustomGameCard card,
      [List<CustomGameCard>? queued]) {
    var colorlessNeed = 0;
    final coloredNeeds = <String, int>{};
    final int voidQi = character.hasStatusEffect('energy_negative_ultimate');

    void accumulate(CustomGameCard c) {
      colorlessNeed += c.cost;
      for (final entry in _cardCostColored(c).entries) {
        coloredNeeds[entry.key] =
            (coloredNeeds[entry.key] ?? 0) + entry.value + voidQi;
      }
    }

    if (queued != null) {
      for (final queuedCard in queued) {
        accumulate(queuedCard);
      }
    }
    accumulate(card);

    if (colorlessNeed > character.energy) return false;

    // 有色费用：每色先扣本色气，缺口由无极之气补齐（无极全色共享，按各颜色缺口之和校验）
    var ultimateNeed = 0;
    for (final entry in coloredNeeds.entries) {
      final yangId = kCostColorStatusIds[entry.key];
      if (yangId == null) continue;
      ultimateNeed +=
          math.max(0, entry.value - character.hasStatusEffect(yangId));
    }
    return ultimateNeed <= character.hasStatusEffect(kWildcardStatusId);
  }

  /// 支付卡牌费用：无色扣能量，有色先扣本色气、缺口自动扣无极之气。
  /// 虚空之气（energy_negative_ultimate）每层使所有有色费用 +1，无上限（共识 5）。
  /// 调用前须已通过 _canPayCardCost 检查；支付失败（资源被中途消耗等意外情况）时
  /// 返回 false 且不扣除任何费用。
  bool _payCardCost(BattleCharacter character, CustomGameCard card) {
    final colorlessNeed = card.cost;

    final pending = <(String, int)>[];
    var ultimateNeed = 0;
    final int voidQi = character.hasStatusEffect('energy_negative_ultimate');
    for (final entry in _cardCostColored(card).entries) {
      final yangId = kCostColorStatusIds[entry.key];
      if (yangId == null) continue;
      final need = entry.value + voidQi;
      final ownPaid = math.min(character.hasStatusEffect(yangId), need);
      pending.add((yangId, ownPaid));
      ultimateNeed += need - ownPaid;
    }

    if (colorlessNeed > character.energy ||
        ultimateNeed > character.hasStatusEffect(kWildcardStatusId)) {
      engine.warning('卡牌 [${card.data['name']}] 支付失败：资源不足');
      return false;
    }

    // 无色费用 = 移除元气（energy_positive_life）状态层数；
    // 入队检查与上方校验已保证存量充足，资源类的全有或全无语义不会截断
    // 资源气行显示由 removeStatusEffect 的钩子自动刷新
    if (colorlessNeed > 0) {
      character.removeStatusEffect('energy_positive_life',
          amount: colorlessNeed);
    }

    for (final (statusId, amount) in pending) {
      if (amount > 0) {
        character.removeStatusEffect(statusId, amount: amount);
      }
    }
    if (ultimateNeed > 0) {
      character.removeStatusEffect(kWildcardStatusId, amount: ultimateNeed);
    }

    // 支付反馈（计划 §6.2）：有色费用按气种弹出负量跳字（无极抵扣单独标注）
    for (final (statusId, amount) in pending) {
      if (amount > 0) {
        character.addHintText('${engine.locale('status_$statusId')} -$amount',
            color: getResourceColor(statusId));
      }
    }
    if (ultimateNeed > 0) {
      character.addHintText(
          '${engine.locale('status_$kWildcardStatusId')} -$ultimateNeed',
          color: getResourceColor(kWildcardStatusId));
    }
    return true;
  }

  /// 刷新指定一侧的资源气行显示（气状态增删/层数变化时由 BattleCharacter 调用）
  void refreshQiDisplay(bool isHero) {
    final display = isHero ? heroEnergyDisplay : enemyEnergyDisplay;
    final character = isHero ? hero : enemy;
    if (display.isLoaded) display.refresh(character);
  }

  /// 刷新手牌置灰状态：不满足费用（含队列占用）的非已入队卡牌置灰（§6.2 可打出高亮）。
  /// 非己方回合全部置灰。置灰通过 isEnabled 切换 invalid paint（卡面灰度、文字半透明），
  /// 只影响绘图不影响交互：悬浮提示仍可用，打出由 _enqueueCard 的费用硬检查拦截。
  void refreshHandAffordability() {
    for (final c in heroHandZone.cards) {
      final card = c as CustomGameCard;
      final grayed = !heroTurn ||
          (!_cardQueue.contains(card) &&
              !_canPayCardCost(hero, card, _cardQueue.toList()));
      card.isEnabled = !grayed;
    }
  }

  /// 生成卡牌缺少资源的悬浮提示文本（每行一种缺少的资源）。
  /// "拥有"按 本色存量 + 无极存量 计算（无极可抵任意有色费用）。
  /// 有色需求含虚空之气增费（每层 +1，无上限）。
  String _missingCostReport(CustomGameCard card) {
    final lines = <String>[];
    final colorlessNeed = card.cost;
    if (colorlessNeed > hero.energy) {
      lines.add(engine.locale('battlecard_cost_lacking_hint', interpolations: [
        engine.locale('status_energy_positive_life'),
        colorlessNeed,
        hero.energy,
      ]));
    }
    final ultimateStock = hero.hasStatusEffect(kWildcardStatusId);
    final int voidQi = hero.hasStatusEffect('energy_negative_ultimate');
    for (final entry in _cardCostColored(card).entries) {
      final yangId = kCostColorStatusIds[entry.key];
      if (yangId == null) continue;
      final need = entry.value + voidQi;
      final stock = hero.hasStatusEffect(yangId) + ultimateStock;
      if (need > stock) {
        lines
            .add(engine.locale('battlecard_cost_lacking_hint', interpolations: [
          engine.locale('status_$yangId'),
          need,
          stock,
        ]));
      }
    }
    return lines.join('\n');
  }

  /// 将卡牌加入待打出队列
  void _enqueueCard(CustomGameCard card) {
    // 只能在自己的回合入队（统一生命周期下资源跨对方回合保留，仅作展示）
    if (!heroTurn || battleResult != null) return;

    // 验证不重复入队
    if (_cardQueue.contains(card)) return;

    // 验证卡牌在手牌中
    if (!heroHandZone.cards.contains(card)) return;

    // 验证费用足够（无色能量 + 有色气，含队列中已入队卡牌的占用）
    if (!_canPayCardCost(hero, card, _cardQueue.toList())) {
      engine.info('资源不足，无法入队: ${card.data['name']}');
      return;
    }

    // 入队并标记
    _cardQueue.add(card);
    card.showGlow = true;
    card.isSelected = true;

    // 队列占用变化，刷新其余手牌的置灰状态
    refreshHandAffordability();

    Hovertip.hide(card);

    // 清除卡牌交互
    // heroHandZone.clearCardInteraction(card);

    engine.info('卡牌入队: ${card.data['name']}, 队列长度: ${_cardQueue.length}');
  }

  /// 处理待打出队列（异步单线程）
  Future<void> _processCardQueue() async {
    // 防止重入
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (_cardQueue.isNotEmpty) {
        // 检查中断条件
        if (_isRestarting ||
            battleEnded ||
            battleResult != null ||
            _endPlayerTurn) {
          break;
        }

        final card = _cardQueue.removeFirst();
        card.clearInteraction();
        // 从 cards 列表中移除，避免被 applySpread 重新定位
        heroHandZone.removeCardByUniqueId(card.uniqueId, updateIndex: false);

        // 执行打出逻辑
        await _playCard(card);
      }

      // 清空队列并处理剩余卡牌
      for (final card in _cardQueue) {
        card.showGlow = false;
        card.isSelected = false;
        if (_isRestarting) {
          // 重启战斗：放回手牌区
          heroHandZone.tryAddCard(card);
          heroHandZone.enableCardInteraction(card);
        } else {
          // 直接移到弃牌堆，不要放回手牌区
          card.isFlipped = true;
          card.clearInteraction();
          heroDiscardZone.tryAddCard(card);
        }
      }
      _cardQueue.clear();

      if (_isRestarting) {
        await heroHandZone.sortCards();
      } else {
        await heroDiscardZone.sortCards();
      }
      heroHandZone.updateIndices();
      // 队列处理完成后，整理手牌区
      await heroHandZone.sortCards();
      // 队列结算完毕（资源与占用均已变化），刷新置灰状态
      refreshHandAffordability();
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// 执行单张卡牌的打出流程
  Future<void> _playCard(CustomGameCard card) async {
    engine.info('开始打出卡牌: ${card.data['name']}');

    // 1. 扣除费用（无色能量 + 有色气，先本色后无极）
    if (!_payCardCost(hero, card)) {
      // 入队时已保证可支付，此处失败属意外情况：退回手牌并中断本次打出
      heroHandZone.tryAddCard(card);
      await heroHandZone.sortCards();
      refreshHandCardDescriptions();
      return;
    }
    heroHandZone.energy = hero.energy;

    card.clearInteraction();
    // 2. 卡牌结算
    await hero.onUseCard(card);

    // 3. 翻面并移到弃牌堆
    card.isFlipped = true;
    card.showGlow = false;

    if (card.data['isEphemeral'] == true) {
      // 易逝卡牌（符箓）：打出后碎裂消失，不进弃牌堆；
      // 标记 usedInBattle 供战斗结束时的使用次数结算识别
      card.data['usedInBattle'] = true;
      world.add(CardShatterEffect(
        position: card.absolutePosition,
        size: card.size.clone(),
        priority: kTopLayerAnimationPriority,
      ));
      card.removeFromParent();
    } else {
      // 卡牌已经在入队时从 heroHandZone.cards 移除，直接移到弃牌堆
      heroDiscardZone.tryAddCard(card);
      await heroDiscardZone.sortCards();
    }

    // 当前卡牌完整结算并处理去向后立即检查胜负，避免队列中的后续卡牌继续执行。
    _checkBattleResult();

    refreshHandCardDescriptions();
    // 资源已扣除，刷新置灰状态
    refreshHandAffordability();

    engine.info('卡牌打出完成: ${card.data['name']}, 剩余能量: ${hero.energy}');
  }

  void onPlayerSelectedCard(CustomGameCard? card) {
    // null 表示结束回合
    if (card == null) {
      _endPlayerTurn = true;
      return;
    }

    // 加入队列
    _enqueueCard(card);

    // 启动队列处理器（不 await，让它在后台运行）
    _processCardQueue();
  }

  /// 敌方简单AI：血量<50%优先buff，否则优先attack
  CustomGameCard _enemySelectCard(List<CustomGameCard> hand) {
    final buffs = hand.where((c) {
      final mainAffix = c.data['affixes'][0];
      return mainAffix['category'] == 'buff';
    }).toList();
    final attacks = hand.where((c) {
      final mainAffix = c.data['affixes'][0];
      return mainAffix['category'] == 'attack';
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

  /// 在结算边界检查战斗是否结束。
  /// 同时死亡时保持既有规则：优先判定敌方死亡，即英雄胜利。
  bool _checkBattleResult({bool checkRoundLimit = false}) {
    if (battleResult != null) return true;

    if (enemy.life <= 0) {
      battleResult = true;
    } else if (hero.life <= 0) {
      battleResult = false;
    } else if (checkRoundLimit &&
        endBattleAfterRounds > 0 &&
        roundCount >= endBattleAfterRounds) {
      battleResult = hero.life > enemy.life;
    }

    if (battleResult != null) {
      endTurnButton.isEnabled = false;
      return true;
    }
    return false;
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

    // 软狂暴：roundCount > 8 后，在本次普通行动回合开始前叠加 1 层劫气。
    // 额外回合位于下方循环内，不会再次叠加。
    if (roundCount > 0 && roundCount > kBattleRoundLimit) {
      currentCharacter.addStatusEffect('debuff_tribulation', amount: 1);
    }

    do {
      final isFirstAction = currentCharacter.turnCount == 0;
      currentCharacter.turnCount += 1;

      final drawCount =
          GameLogic.getHandLimitForRank(currentCharacter.data['rank'])['limit']
              as int;
      final drawn =
          await drawCardsToHand(deckZone, discardZone, handZone, drawCount);

      // ① 回合开始回调（死气/劫气/DOT/缓慢/幻觉等；其中死气消耗 1 层失去 10% 生命）
      await currentCharacter.onStartTurn(isExtra: extraTurn);

      extraTurn = false;

      // 回合开始效果造成死亡后，不再继续资源或出牌阶段。
      if (_checkBattleResult()) return;

      final skipPlayPhase = (drawn == 0 && handZone.cards.isEmpty) ||
          currentCharacter.turnFlags['skipTurn'] == true;

      // ② 统一生命周期：清空上回合残留的所有阳气（阴气永久存在；煞气未用量返回 karma 池）
      // ③ 结算本回合新产出（元气 rank+3 / 剑气 / 怒气 / 灵气 / 煞气池提取）
      // 顺序显式保证：先清空残留，再结算产出
      // 各角色第一次行动保留战斗开始时获得的阳气；从下一次行动开始正常清理。
      // 资源气行显示由 addStatusEffect/removeStatusEffect 的钩子自动刷新
      if (!isFirstAction) {
        currentCharacter.clearResourceEffects();
      }
      currentCharacter.produceTurnStartResources();

      final opponentStatus =
          _prepareStatus(currentCharacter, StatusCircumstances.start_turn);
      for (final statusId in opponentStatus.keys) {
        final value = opponentStatus[statusId]!;
        currentOpponent.addStatusEffect(statusId,
            amount: value, handleCallback: false);
      }
      // 回合开始注入的状态（如施加给对方的弱点）会影响预测数值
      refreshHandCardDescriptions();
      // 新产出已结算，刷新手牌置灰状态
      refreshHandAffordability();

      if (skipPlayPhase) {
        endTurnButton.isEnabled = false;
      } else if (heroTurn) {
        endTurnButton.isEnabled = true;

        // 重置结束回合标志
        _endPlayerTurn = false;

        // 等待玩家结束回合（通过 _shouldEndTurn 标志）
        while (_isProcessingQueue ||
            (battleResult == null && !_isRestarting && !_endPlayerTurn)) {
          // 等待队列处理器空闲
          // if (!_isProcessingQueue && _cardQueue.isEmpty) {
          // 检查是否还有可打出的卡牌
          // final affordableCards = heroHandZone.cards
          //     .where((c) => (c as CustomGameCard).cost <= hero.energy)
          //     .toList();

          // if (affordableCards.isEmpty) {
          //   // 没有可打出的卡牌，自动结束回合
          //   engine.info('没有可打出的卡牌，自动结束回合');
          //   break;
          // }
          // }

          // 短暂等待，避免忙等
          await Future.delayed(Duration(milliseconds: 50));
        }

        endTurnButton.isEnabled = false;
      } else {
        while (!_isRestarting &&
            battleResult == null &&
            handZone.cards.isNotEmpty &&
            currentCharacter.energy > 0) {
          final affordable = handZone.cards
              .where(
                  (c) => _canPayCardCost(currentCharacter, c as CustomGameCard))
              .toList()
              .cast<CustomGameCard>();
          if (affordable.isEmpty) break;

          final selectedCard = _enemySelectCard(affordable);
          _payCardCost(currentCharacter, selectedCard);

          selectedCard.isFlipped = false;
          await currentCharacter.onUseCard(selectedCard);
          selectedCard.isFlipped = true;
          if (selectedCard.data['isEphemeral'] == true) {
            world.add(CardShatterEffect(
              position: selectedCard.absolutePosition,
              size: selectedCard.size.clone(),
              priority: kTopLayerAnimationPriority,
            ));
            selectedCard.removeFromPile(removeFromGame: true);
          } else {
            discardZone.tryAddCard(selectedCard);
            await discardZone.sortCards();
          }

          // 当前卡牌完整结算并处理去向后终止已分出胜负的战斗。
          if (_checkBattleResult()) break;
        }
        // 敌方出牌后状态可能已变化（如施加给英雄的削弱），刷新手牌预测
        refreshHandCardDescriptions();
      }

      if (_isRestarting || _checkBattleResult()) return;

      await currentCharacter.onEndTurn();

      // 回合结束资源和状态效果造成死亡后，不再判定额外回合或切换回合。
      if (_checkBattleResult()) return;

      // 速度达到阈值时 speed_quick 脚本在 onEndTurn 中写入 extraTurn 标记，
      // 在此读取并重复整个回合体（onStartTurn 会清空 turnFlags，标记不会泄漏）
      if (currentCharacter.turnFlags['extraTurn'] == true) {
        extraTurn = true;
      }

      // final opponentEndStatus =
      //     _prepareStatus(currentCharacter, StatusCircumstances.end_turn);
      // for (final statusId in opponentEndStatus.keys) {
      //   final value = opponentEndStatus[statusId]!;
      //   currentOpponent.addStatusEffect(statusId,
      //       amount: value, handleCallback: false);
      // }
      // // 回合结束注入的状态（如施加给对方的弱点）会影响预测数值
      // refreshHandCardDescriptions();

      await clearHand(handZone, discardZone);
    } while (extraTurn);

    heroTurn = !heroTurn;
    currentCharacter = heroTurn ? hero : enemy;
    currentOpponent = heroTurn ? enemy : hero;
    // 回合归属切换：非己方回合期间整手置灰
    refreshHandAffordability();

    if (currentCharacter == hero) {
      roundCount += 1;
    }

    _checkBattleResult(checkRoundLimit: true);
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

      // 易逝卡牌（符箓）计数结算：战斗中实际打出过的符箓使用次数 -1（未打出不扣）
      final usedScrollIds = <dynamic>[
        for (final card in heroDeck)
          if (card.data['isEphemeral'] == true &&
              card.data['usedInBattle'] == true)
            card.data['id']
      ];
      if (usedScrollIds.isNotEmpty) {
        engine.hetu.invoke('settleScrollCharges',
            namespace: 'Player', positionalArgs: [usedScrollIds]);
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
                    mouseCursor: GameCursors.hovered,
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
                                _endPlayerTurn = true;
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
