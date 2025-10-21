import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:provider/provider.dart';

import '../../ui.dart';
import '../../logic/logic.dart';
import 'character.dart';
import 'battledeck_zone.dart';
import '../../engine.dart';
import 'versus_banner.dart';
import '../common.dart';
import '../../data/game.dart';
import 'common.dart';
import 'drop_menu.dart';
import '../../state/states.dart';
import '../../widgets/ui_overlay.dart';

const kMinTurnDuration = 1500;
const kBattleRoundLimit = 5;

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
  final _focusNode = FocusNode();

  late FpsComponent fps;

  final String backgroundImageId;

  late final SpriteComponent2 background;
  late final SpriteComponent _victoryPrompt, _defeatPrompt;

  late final VersusBanner versusBanner;

  late final BattleCharacter hero, enemy;
  late final BattleDeckZone heroDeckZone, enemyDeckZone;
  final dynamic heroData, enemyData;
  late final List<CustomGameCard> heroDeck, enemyDeck;

  final bool isSneakAttack;
  final bool isAutoBattle;

  int roundCount = 0;

  // 先手角色
  late final bool isFirsthand;
  // 当前是否是玩家回合
  late bool heroTurn;
  late BattleCharacter currentCharacter, currentOpponent;

  bool? battleResult;

  late final SpriteButton nextTurnButton, restartButton;

  bool battleStarted = false;
  bool battleEnded = false;

  final Map<String, dynamic> battleFlags = {};

  FutureOr<void> Function()? onBattleStart;
  FutureOr<dynamic> Function(bool result, int roundCount)? onBattleEnd;

  bool isDetailedHovertip = false;

  final int endBattleAfterRounds;

  BattleScene({
    required this.heroData,
    required this.enemyData,
    required this.isSneakAttack,
    this.isAutoBattle = true,
    this.onBattleStart,
    this.onBattleEnd,
    this.endBattleAfterRounds = 0,
    required this.backgroundImageId,
  }) : super(
          context: engine.context,
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
  }

  Map<String, int> _prepareStatus(
      BattleCharacter character, StatusCircumstances circumstance) {
    for (final statusId in kSelfStatusOnCircumstance) {
      final passiveId = '${circumstance.name}_with_$statusId';

      final passiveData = character.data['passives'][passiveId];
      if (passiveData != null) {
        int? value = passiveData['value'];
        if (value == null) {
          engine.warn('passiveData has no field `value`! $passiveData');
        }
        character.addStatusEffect(statusId,
            amount: value, handleCallback: false);
      }

      final potionPassiveData = character.data['potionPassives'][passiveId];
      if (potionPassiveData != null) {
        int? value = potionPassiveData['value'];
        if (value == null) {
          engine.warn(
              'potionPassiveData has no field `value`! $potionPassiveData');
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
          engine.warn('passiveData $passiveData has no field `value`!');
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
        return GameData.createBattleCard(data, deepCopyData: true);
      }).toList();
    } else {
      return [];
    }
  }

  @override
  void onStart([dynamic arguments = const {}]) {
    super.onStart();

    context.read<EnemyState>().setPrebattleVisible(false);
    context.read<HoverContentState>().hide();
    context.read<ViewPanelState>().clearAll();
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

    _victoryPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: Sprite(await Flame.images.load('battle/victory.png')),
      size: Vector2(480.0, 240.0),
    );
    _defeatPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: Sprite(await Flame.images.load('battle/defeat.png')),
      size: Vector2(480.0, 240.0),
    );

    heroDeckZone = BattleDeckZone(
      position: GameUI.p1BattleDeckZonePosition,
      cards: heroDeck,
      focusedOffset: GameUI.battleCardFocusedOffset,
      pileStyle: PileStyle.queue,
      reverseX: false,
    );
    world.add(heroDeckZone);

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
      pileStyle: PileStyle.queue,
      reverseX: true,
    );
    world.add(enemyDeckZone);

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

    versusBanner = VersusBanner(
      position: Vector2(center.x, center.y - 120),
      hero: heroData,
      enemyData: enemyData,
    );
    camera.viewport.add(versusBanner);

    final heroRank = heroData['rank'];
    final enemyRank = enemyData['rank'];

    if (heroRank == enemyRank) {
      final heroLevel = heroData['level'];
      final enemyLevel = enemyData['level'];
      if (heroLevel == enemyLevel) {
        isFirsthand =
            heroData['stats']['dexterity'] >= enemyData['stats']['dexterity'];
      } else {
        isFirsthand = heroLevel > enemyLevel;
      }
    } else {
      isFirsthand = heroRank > enemyRank;
    }

    restartButton = SpriteButton(
      spriteId: 'ui/button2.png',
      text: engine.locale('restart'),
      anchor: Anchor.center,
      position: Vector2(
          center.x,
          heroDeckZone.position.y -
              GameUI.buttonSizeMedium.y * 2 -
              GameUI.indent),
      size: Vector2(100.0, 40.0),
    );
    restartButton.onTap = (_, __) async {
      restartButton.isVisible = false;
      _victoryPrompt.removeFromParent();
      _defeatPrompt.removeFromParent();
      nextTurnButton.isVisible = true;
      nextTurnButton.text = engine.locale('start');
      nextTurnButton.onTap = (_, __) {
        if (engine.config.debugMode || !isAutoBattle) {
          nextTurn();
        } else {
          startAutoBattle();
        }
      };
      await _onBattleStart();
    };

    showStartPrompt();
  }

  Future<void> showStartPrompt() async {
    await versusBanner.fadeIn(duration: 1.2);

    nextTurnButton = SpriteButton(
      spriteId: 'ui/button.png',
      text: engine.locale('start'),
      anchor: Anchor.center,
      position: Vector2(
          center.x, heroDeckZone.position.y - GameUI.buttonSizeMedium.y),
      size: Vector2(100.0, 40.0),
    );
    nextTurnButton.onTap = (_, __) {
      if (engine.config.debugMode || !isAutoBattle) {
        nextTurn();
      } else {
        startAutoBattle();
      }
    };
    camera.viewport.add(nextTurnButton);
  }

  Future<void> _onBattleStart() async {
    battleEnded = false;
    battleResult = null;
    hero.reset();
    enemy.reset();
    heroDeckZone.reset();
    enemyDeckZone.reset();

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
    nextTurnButton.text = engine.locale('nextTurn');

    await onBattleStart?.call();
  }

  Future<void> nextTurn() async {
    if (!battleStarted) {
      battleStarted = true;
      versusBanner.moveTo(
        duration: 0.3,
        toPosition: Vector2(center.x, GameUI.hugeIndent),
      );
      camera.viewport.add(restartButton);
      await _onBattleStart();
    } else if (battleResult == null) {
      final skipped = await _startTurn();
      if (skipped) {
        _startTurn();
      }
    } else {
      _onBattleEnd();
    }
  }

  CustomGameCard nextCard() {
    assert(currentCharacter.deckZone.cards.isNotEmpty);
    assert(currentCharacter.deckZone.current != null);
    CustomGameCard card;
    if (currentCharacter.deckZone.current!.next == null) {
      for (final card in currentCharacter.deckZone.cards) {
        card.isEnabled = true;
      }

      currentCharacter.handleStatusEffectCallback('self_deck_end');
      currentCharacter.opponent!
          .handleStatusEffectCallback('opponent_deck_end');

      card = currentCharacter.deckZone.cards.first as CustomGameCard;

      currentCharacter.deckZone.isFirstCard = true;
      currentCharacter.deckZone.round += 1;
    } else {
      card = currentCharacter.deckZone.current!.next as CustomGameCard;
    }
    return card;
  }

  Future<bool> _startTurn() async {
    restartButton.isVisible = false;
    nextTurnButton.isVisible = false;
    bool extraTurn = false;
    bool skipTurn = false;

    engine.hetu.assign('self', currentCharacter);
    engine.hetu.assign('opponent', currentOpponent);

    currentCharacter.priority = kTopLayerAnimationPriority;
    currentOpponent.priority = 0;

    if (currentCharacter.deckZone.cards.isNotEmpty) {
      CustomGameCard card = currentCharacter.deckZone.current!;
      do {
        final tik = DateTime.now().millisecondsSinceEpoch;

        if (currentCharacter.deckZone.isFirstCard) {
          final oppponentStatus =
              _prepareStatus(currentCharacter, StatusCircumstances.start_deck);
          for (final statusId in oppponentStatus.keys) {
            final value = oppponentStatus[statusId]!;
            currentOpponent.addStatusEffect(statusId,
                amount: value, handleCallback: false);
          }
          currentCharacter.deckZone.isFirstCard = false;

          if (currentCharacter.deckZone.round >= kBattleRoundLimit) {
            // 如果回合数超过上限，角色会获得死气的 debuff
            currentCharacter.addStatusEffect('energy_negative_life',
                amount: currentCharacter.deckZone.round);
          }
        }

        final oppponentStatus =
            _prepareStatus(currentCharacter, StatusCircumstances.start_turn);
        for (final statusId in oppponentStatus.keys) {
          final value = oppponentStatus[statusId]!;
          currentOpponent.addStatusEffect(statusId,
              amount: value, handleCallback: false);
        }

        final turnDetails =
            await currentCharacter.onTurnStart(card, isExtra: extraTurn);
        final delta = DateTime.now().millisecondsSinceEpoch - tik;
        if (delta < kMinTurnDuration) {
          await Future.delayed(
              Duration(milliseconds: kMinTurnDuration - delta));
        }
        bool skipTurn = turnDetails['skipTurn'] ?? false;
        if (!skipTurn) {
          final turnEndDetails = await currentCharacter.onTurnEnd(card);
          card.isEnabled = false;
          card = currentCharacter.deckZone.current = nextCard();
          extraTurn = turnEndDetails['extraTurn'] ?? false;

          final oppponentStatus =
              _prepareStatus(currentCharacter, StatusCircumstances.end_turn);
          for (final statusId in oppponentStatus.keys) {
            final value = oppponentStatus[statusId]!;
            currentOpponent.addStatusEffect(statusId,
                amount: value, handleCallback: false);
          }
        }
      } while (extraTurn);
    } else {
      skipTurn = true;
    }

    heroTurn = !heroTurn;
    currentCharacter = heroTurn ? hero : enemy;
    currentOpponent = heroTurn ? enemy : hero;

    if (currentCharacter == hero) {
      roundCount += 1;
    }

    // true表示英雄胜利，false表示英雄失败，null表示战斗未结束
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

    nextTurnButton.isVisible = true;
    restartButton.isVisible = true;

    return skipTurn;
  }

  void _endScene() async {
    context.read<EnemyState>().clear();
    engine.hetu.assign('enemy', null);
    engine.hetu.assign('self', null);
    engine.hetu.assign('opponent', null);
    engine.hetu.assign('battleFlags', null);
    final result = await onBattleEnd?.call(battleResult ?? false, roundCount);
    if (result != true) {
      engine.popScene(clearCache: true);
    }
  }

  Future<void> _onBattleEnd() async {
    if (battleResult == true) {
      camera.viewport.add(_victoryPrompt);
      enemy.setState(kDefeatState);

      // 如果开启了煞气天赋，战胜对手后增加 1 点煞气
      if (heroData['passives']['enable_karma'] != null) {
        heroData['karma'] += 1;
      }
    } else {
      battleResult = false;
      camera.viewport.add(_defeatPrompt);
      hero.setState(kDefeatState);
    }

    final heroName = '${hero.data['name']}(hero)';
    final enemyName = '${enemy.data['name']}(enemy)';
    engine.debug(
        'Battle between $heroName and $enemyName ended. ${battleResult! ? heroName : enemyName} won!');

    battleEnded = true;

    final heroPotionPassives = hero.data['potionPassives'];
    if (heroPotionPassives.isNotEmpty) {
      heroPotionPassives.clear();
      engine.hetu
          .invoke('characterCalculateStats', positionalArgs: [hero.data]);
    }

    final enemyPotionPassives = enemy.data['potionPassives'];
    if (enemyPotionPassives.isNotEmpty) {
      enemyPotionPassives.clear();
      engine.hetu
          .invoke('characterCalculateStats', positionalArgs: [enemy.data]);
    }

    bool hasScroll = false;
    for (final card in heroDeck) {
      if (card.data['isEphemeral'] == true) {
        hasScroll = true;
        engine.hetu.invoke('dismantleCard',
            namespace: 'Player', positionalArgs: [card.data]);
      }
    }
    if (hasScroll) {
      /// 清除卡牌图书馆场景的缓存，因为需要重新生成卡组的内容组件
      engine.clearCachedScene(Scenes.library);
    }

    if (!nextTurnButton.isMounted) {
      camera.viewport.add(nextTurnButton);
    }
    nextTurnButton.text = engine.locale('end');
    nextTurnButton.onTap = (_, __) => _endScene();

    final hpRestoreRate = GameLogic.getHPRestoreRateAfterBattle(roundCount);
    final int life = hero.life;
    if (battleResult == true) {
      final replenish = (hero.lifeMax * hpRestoreRate).round();
      engine.debug('战斗结果：[$battleResult], 角色生命恢复：$replenish');
      final int newLife = life + replenish;
      hero.setLife(newLife);
    } else {
      if (life <= 0) {
        hero.setLife(1);
      } else if (life > hero.lifeMax) {
        hero.setLife(hero.lifeMax);
      }
    }
    engine.hetu
        .invoke('setCharacterLife', positionalArgs: [hero.data, hero.life]);
  }

  Future<void> startAutoBattle() async {
    nextTurnButton.removeFromParent();

    await versusBanner.moveTo(
      duration: 0.3,
      toPosition: Vector2(center.x, GameUI.hugeIndent),
    );
    await _onBattleStart();

    do {
      await _startTurn();
    } while (battleResult == null);

    await _onBattleEnd();
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    _focusNode.requestFocus();

    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          engine.debug('keydown: ${event.logicalKey.debugName}');
          switch (event.logicalKey) {
            case LogicalKeyboardKey.controlLeft:
            case LogicalKeyboardKey.controlRight:
              isDetailedHovertip = !isDetailedHovertip;
          }
        }
      },
      child: Stack(
        children: [
          SceneWidget(
            scene: this,
            loadingBuilder: loadingBuilder,
            overlayBuilderMap: overlayBuilderMap,
            initialActiveOverlays: initialActiveOverlays,
          ),
          GameUIOverlay(
            enableHeroInfo: false,
            showNpcs: false,
            actions: engine.config.debugMode
                ? [
                    BattleDropMenu(
                      onSelected: (item) async {
                        switch (item) {
                          case BattleDropMenuItems.console:
                            GameUI.showConsole(context);
                          case BattleDropMenuItems.exit:
                            _endScene();
                        }
                      },
                    )
                  ]
                : null,
          ),
        ],
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);
  }

  // @override
  // void render(Canvas canvas) {
  //   super.render(canvas);

  //   // if (engine.config.debugMode || engine.config.showFps) {
  //   //   drawScreenText(
  //   //     canvas,
  //   //     'FPS: ${fps.fps.toStringAsFixed(0)}',
  //   //     config: ScreenTextConfig(
  //   //       textStyle: const TextStyle(fontSize: 20),
  //   //       size: GameUI.size,
  //   //       anchor: Anchor.topCenter,
  //   //       padding: const EdgeInsets.only(top: 40),
  //   //     ),
  //   //   );
  //   // }
  // }
}
