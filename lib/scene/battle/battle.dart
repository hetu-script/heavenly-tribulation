import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/widgets/ui_overlay.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:provider/provider.dart';

import '../../game/ui.dart';
import '../../game/logic.dart';
import 'character.dart';
import 'battledeck_zone.dart';
import '../../engine.dart';
import 'versus_banner.dart';
import '../common.dart';
import '../../game/data.dart';
import 'common.dart';
import 'drop_menu.dart';
import '../../state/states.dart';

const kMinTurnDuration = 1500;
const kBattleRoundLimit = 5;

/// 属性效果对应的永久状态，值是正面状态和负面状态的元组
const kStatsToPermenantEffects = {
  'unarmedEnhance': ('enhance_unarmed', 'weaken_unarmed'),
  'weaponEnhance': ('enhance_weapon', 'weaken_weapon'),
  'spellEnhance': ('enhance_spell', 'weaken_spell'),
  'curseEnhance': ('enhance_curse', 'weaken_curse'),
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

  late final SpriteComponent2 background;
  late final SpriteComponent _victoryPrompt, _defeatPrompt;

  late final VersusBanner versusBanner;

  late final BattleCharacter hero, enemy;
  late final BattleDeckZone heroDeckZone, enemyDeckZone;
  final dynamic heroData, enemyData;
  late final List<CustomGameCard> heroDeck, enemyDeck;

  final bool isSneakAttack;
  final bool isAutoBattle;

  int turn = 0;
  int turnCount = 0;

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
  FutureOr<void> Function(bool? result)? onBattleEnd;

  bool isDetailedHovertip = false;

  BattleScene({
    required this.heroData,
    required this.enemyData,
    required this.isSneakAttack,
    this.isAutoBattle = true,
    this.onBattleStart,
    this.onBattleEnd,
  }) : super(
          context: engine.context,
          id: Scenes.battle,
          bgm: engine.bgm,
          bgmFile: 'war-drums-173853.mp3',
          bgmVolume: engine.config.musicVolume,
        );

  void _prepareBattleStart(BattleCharacter character) {
    for (final statName in kStatsToPermenantEffects.keys) {
      final int value = character.data['stats'][statName];
      final (positiveEffectId, negativeEffectId) =
          kStatsToPermenantEffects[statName]!;
      if (value > 0) {
        character.addStatusEffect(positiveEffectId,
            amount: value, handleCallback: false);
      } else if (value < 0) {
        character.addStatusEffect(negativeEffectId,
            amount: -value, handleCallback: false);
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
          engine.warn('passiveData $passiveData has no field `value`!');
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

  List<CustomGameCard> getDeck(dynamic characterData) {
    final List decks = characterData['battleDecks'];
    final index = characterData['battleDeckIndex'];
    if (decks.isNotEmpty && index >= 0 && index < decks.length) {
      final deckInfo = decks[index];
      final List cardIds = deckInfo['cards'];
      return cardIds.map((id) {
        final data = characterData['cardLibrary'][id];
        assert(data != null);
        return GameData.createBattleCardFromData(data, deepCopyData: true);
      }).toList();
    } else {
      return [];
    }
  }

  @override
  void onMount() {
    super.onMount();

    context.read<EnemyState>().setPrebattleVisible(false);
    context.read<HoverContentState>().hide();
    context.read<ViewPanelState>().clearAll();
  }

  @override
  void onLoad() async {
    super.onLoad();

    engine.hetu.assign('enemy', enemyData);
    engine.hetu.assign('battleFlags', battleFlags);

    heroDeck = getDeck(heroData);
    enemyDeck = getDeck(enemyData);

    background = SpriteComponent2(
      spriteId: 'battle/scene/002.png',
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

    final heroModelId = heroData['model'];
    final Set<String> heroAnimationStates = {};
    final Set<String> heroOverlayAnimationStates = {};
    for (final card in heroDeck) {
      final affixes = card.data['affixes'];
      for (final affix in affixes) {
        String? startup = affix['animation']?['startup'];
        String? recovery = affix['animation']?['recovery'];
        List<String> transitions =
            List<String>.from(affix['animation']?['transitions'] ?? []);
        List<String> overlays =
            List<String>.from(affix['animation']?['overlays'] ?? []);
        if (startup != null) heroAnimationStates.add(startup);
        if (recovery != null) heroAnimationStates.add(recovery);
        heroAnimationStates.addAll(transitions);
        heroOverlayAnimationStates.addAll(overlays);
      }
    }
    heroAnimationStates.remove('');
    heroOverlayAnimationStates.remove('');
    hero = BattleCharacter(
      position: GameUI.p1CharacterAnimationPosition,
      size: GameUI.heroSpriteSize,
      isHero: true,
      modelId: heroModelId,
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

    final enemyModelId = enemyData['model'];
    final Set<String> enemyAnimationStates = {};
    final Set<String> enemyOverlayAnimationStates = {};
    for (final card in enemyDeck) {
      final affixes = card.data['affixes'];
      for (final affix in affixes) {
        String? startup = affix['animation']?['startup'];
        String? recovery = affix['animation']?['recovery'];
        List<String> transitions =
            List<String>.from(affix['animation']?['transitions'] ?? []);
        List<String> overlays =
            List<String>.from(affix['animation']?['overlays'] ?? []);
        if (startup != null) enemyAnimationStates.add(startup);
        if (recovery != null) enemyAnimationStates.add(recovery);
        enemyAnimationStates.addAll(transitions);
        enemyOverlayAnimationStates.addAll(overlays);
      }
    }
    enemyAnimationStates.remove('');
    enemyOverlayAnimationStates.remove('');
    enemy = BattleCharacter(
      position: GameUI.p2CharacterAnimationPosition,
      size: GameUI.heroSpriteSize,
      modelId: enemyModelId,
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
      heroData: heroData,
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
    if (!battleEnded) {
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

    if (currentCharacter == hero) {
      turnCount += 1;
    }

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

    if (heroTurn == isFirsthand) {
      ++turn;
    }

    // true表示英雄胜利，false表示英雄失败，null表示战斗未结束
    if (enemy.life <= 0) {
      battleResult = true;
    } else if (hero.life <= 0) {
      battleResult = false;
    }

    nextTurnButton.isVisible = true;
    restartButton.isVisible = true;

    return skipTurn;
  }

  void _endScene() {
    engine.hetu.assign('enemy', null);
    engine.hetu.assign('self', null);
    engine.hetu.assign('opponent', null);
    engine.hetu.assign('battleFlags', null);
    engine.popScene(clearCache: true);
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

    if (!nextTurnButton.isMounted) {
      camera.viewport.add(nextTurnButton);
    }
    nextTurnButton.text = engine.locale('end');
    nextTurnButton.onTap = (_, __) => _endScene();

    final hpRestoreRate = GameLogic.getHPRestoreRateAfterBattle(turnCount);
    final int life = hero.life;
    if (battleResult == true) {
      final int newLife = life + (hero.lifeMax * hpRestoreRate).toInt();
      hero.setLife(newLife);
    }
    hero.data['life'] = hero.life;
    engine.info('战斗结果：[$battleResult], 角色生命恢复：${hero.life - life}');

    await onBattleEnd?.call(battleResult);

    context.read<EnemyState>().clear();
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
  Widget build(BuildContext context) {
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
          SceneWidget(scene: this),
          GameUIOverlay(
            enableHeroInfo: false,
            enableNpcs: false,
            action: engine.config.debugMode
                ? BattleDropMenu(
                    onSelected: (item) async {
                      switch (item) {
                        case BattleDropMenuItems.console:
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => Console(
                              engine: engine,
                              margin: const EdgeInsets.all(50.0),
                              backgroundColor: GameUI.backgroundColor2,
                            ),
                          );
                        case BattleDropMenuItems.exit:
                          await onBattleEnd?.call(false);
                          context.read<EnemyState>().clear();
                          _endScene();
                      }
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
