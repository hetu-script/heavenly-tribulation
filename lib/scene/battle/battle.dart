import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/widgets/ui_overlay.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/sprite_component2.dart';

import '../../game/ui.dart';
import 'character.dart';
import 'battledeck_zone.dart';
import '../../engine.dart';
import 'versus_banner.dart';
import '../common.dart';
import '../../game/data.dart';
import 'common.dart';
import 'drop_menu.dart';

const kMinTurnDuration = 1500;

/// 属性效果对应的永久状态，值是正面状态和负面状态的元组
const kStatsToPermenantEffects = {
  'unarmedEnhance': ('enhance_unarmed', 'weaken_unarmed'),
  'weaponEnhance': ('enhance_weapon', 'weaken_weapon'),
  'spellEnhance': ('enhance_spell', 'weaken_spell'),
  'curseEnhance': ('enhance_curse', 'weaken_curse'),
  'chaosEnhance': ('enhance_chaos', 'weaken_chaos'),
  'physicalResist': ('resistant_physical', 'weakness_physical'),
  'chiResist': ('resistant_chi', 'weakness_chi'),
  'elementalResist': ('resistant_elemental', 'weakness_elemental'),
  'spiritualResist': ('resistant_spiritual', 'weakness_spiritual'),
};

class BattleScene extends Scene {
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

  // 先手角色
  late final bool isFirsthand;
  // 当前是否是玩家回合
  late bool heroTurn;
  late BattleCharacter currentCharacter, currentOpponent;

  bool? battleResult;

  late final SpriteButton nextTurnButton, restartButton;

  bool battleStarted = false;
  bool battleEnded = false;

  final Map<String, dynamic> gameDetails = {};

  FutureOr<void> Function()? onBattleStart;
  FutureOr<void> Function(bool? result)? onBattleEnd;

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

  void _addPermenantStatus(BattleCharacter character) {
    final stats = character.data['stats'];
    for (final statName in kStatsToPermenantEffects.keys) {
      final int? value = stats[statName];
      if (value != null) {
        final (positiveEffectId, negativeEffectId) =
            kStatsToPermenantEffects[statName]!;
        if (value > 0) {
          character.addStatusEffect(positiveEffectId, amount: value);
        } else if (value < 0) {
          character.addStatusEffect(negativeEffectId, amount: value);
        }
      }
    }
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
  void onLoad() async {
    super.onLoad();

    engine.hetu.assign('enemy', enemyData);

    heroDeck = getDeck(heroData);
    enemyDeck = getDeck(enemyData);

    background = SpriteComponent2(
      spriteId: 'battle/scene/001.png',
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

    final heroSkinId = heroData['characterSkin'];
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
      skinId: heroSkinId,
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

    final enemySkinId = enemyData['characterSkin'];
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
      skinId: enemySkinId,
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

    _addPermenantStatus(hero);
    _addPermenantStatus(enemy);

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
    _addPermenantStatus(hero);
    _addPermenantStatus(enemy);
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
    if (currentCharacter.deckZone.cards.isNotEmpty) {
      CustomGameCard card = currentCharacter.deckZone.current!;
      do {
        final tik = DateTime.now().millisecondsSinceEpoch;
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
        }
      } while (extraTurn);
    } else {
      skipTurn = true;
    }

    heroTurn = !heroTurn;
    currentCharacter = heroTurn ? hero : enemy;
    currentOpponent = heroTurn ? enemy : hero;

    currentCharacter.priority = kTopLayerAnimationPriority;
    currentOpponent.priority = 0;

    if (heroTurn == isFirsthand) {
      ++turn;
    }

    // true表示英雄胜利，false表示英雄失败，null表示战斗未结束

    if (turn >= kTurnLimit) {
      if (hero.life >= enemy.life) {
        battleResult = true;
      } else {
        battleResult = false;
      }
    }

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
    engine.popScene(clearCache: true);
  }

  Future<void> _onBattleEnd() async {
    if (battleResult == true) {
      camera.viewport.add(_victoryPrompt);
      enemy.setState(kDefeatState);
    } else {
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

    await onBattleEnd?.call(battleResult);
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
    return Stack(
      children: [
        SceneWidget(scene: this),
        GameUIOverlay(
          enableHeroInfo: false,
          dropMenu: engine.config.debugMode
              ? BattleDropMenu(
                  onSelected: (item) {
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
                        _endScene();
                    }
                  },
                )
              : null,
        ),
      ],
    );
  }
}
