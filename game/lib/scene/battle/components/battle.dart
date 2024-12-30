import 'dart:async';

// import 'package:samsara/event.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
// import 'package:samsara/event/event.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/cardgame/card.dart';
// import 'package:samsara/gestures.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:flame/flame.dart';
// import 'package:samsara/components/tooltip.dart';
// import 'package:samsara/cardgame/custom_card.dart';

import '../../../ui.dart';
import 'character.dart';
import 'deck_zone.dart';
import '../../../engine.dart';
// import 'status/status.dart';
import 'versus_banner.dart';

const kTurnLimit = 80;

class BattleScene extends Scene {
  late final SpriteComponent background;
  late final SpriteComponent _victoryPrompt, _defeatPrompt;

  late final VersusBanner versusBanner;

  late final BattleCharacter hero, enemy;
  late final BattleDeckZone heroDeckZone, enemyDeckZone;
  final dynamic heroData, enemyData;
  final List<GameCard> heroDeck, enemyDeck;

  final bool isSneakAttack;

  int turn = 0;

  // 先手角色
  late final bool initialMove;
  // 当前是否是玩家回合
  late bool heroTurn;
  late BattleCharacter currentCharacter, currentOpponent;

  bool? battleResult;

  late final SpriteButton nextTurnButton;

  bool battleStarted = false;
  bool battleEnded = false;

  BattleScene({
    required super.controller,
    required super.id,
    required this.heroData,
    required this.enemyData,
    required this.heroDeck,
    required this.enemyDeck,
    required this.isSneakAttack,
    required super.context,
  }) : super(
          bgmFile: 'war-drums-173853.mp3',
          bgmVolume: GameConfig.musicVolume,
        );

  @override
  void onLoad() async {
    super.onLoad();

    background = SpriteComponent(
      sprite: Sprite(await Flame.images.load('battle/scene/bamboo.png')),
      size: size,
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
      pileStructure: PileStructure.queue,
      reverseX: false,
    );
    world.add(heroDeckZone);

    final heroSkinId = heroData['characterSkin'];
    final Set<String> heroAnimationStates = {};
    for (final card in heroDeck) {
      final affixes = card.data['affixes'];
      for (final affix in affixes) {
        final states = affix['animations'];
        if (states is List) {
          for (final state in states) {
            heroAnimationStates.add(state);
            //   heroAnimationStates.add('${state}_$heroSkinId');
          }
        }
      }
    }
    hero = BattleCharacter(
      position: GameUI.p1HeroSpritePosition,
      size: GameUI.heroSpriteSize,
      isHero: true,
      skinId: heroSkinId,
      animationStates: heroAnimationStates,
      data: heroData,
      deckZone: heroDeckZone,
    );
    world.add(hero);

    enemyDeckZone = BattleDeckZone(
      position: GameUI.p2BattleDeckZonePosition,
      cards: enemyDeck,
      focusedOffset: GameUI.battleCardFocusedOffset,
      pileStructure: PileStructure.queue,
      reverseX: true,
    );
    world.add(enemyDeckZone);

    final enemySkinId = enemyData['characterSkin'];
    final Set<String> enemyAnimationStates = {};
    for (final card in enemyDeck) {
      final affixes = card.data['affixes'];
      for (final afix in affixes) {
        final states = afix['animations'];
        if (states is List) {
          for (final state in states) {
            enemyAnimationStates.add(state);
            //   enemyAnimationStates.add('${state}_$enemySkinId');
          }
        }
      }
    }
    enemy = BattleCharacter(
      position: GameUI.p2HeroSpritePosition,
      size: GameUI.heroSpriteSize,
      skinId: enemySkinId,
      animationStates: enemyAnimationStates,
      data: enemyData,
      deckZone: enemyDeckZone,
    );
    world.add(enemy);

    hero.opponent = enemy;
    enemy.opponent = hero;

    versusBanner = VersusBanner(
      position: Vector2(center.x, center.y - 75),
      heroData: heroData,
      enemyData: enemyData,
    );
    world.add(versusBanner);

    showStartPrompt();

    final heroCP = heroData['exp'];
    final enemyCP = enemyData['exp'];

    if (heroCP > enemyCP) {
      initialMove = true;
    } else if (heroCP < enemyCP) {
      initialMove = false;
    } else {
      if (heroData['stats']['dexterity'] >= enemyData['stats']['dexterity']) {
        initialMove = true;
      } else {
        initialMove = false;
      }
    }
  }

  Future<void> showStartPrompt() async {
    await versusBanner.fadeIn(duration: 1.2);

    nextTurnButton = SpriteButton(
      useSimpleStyle: true,
      text: engine.locale('start'),
      priority: 5000,
      anchor: Anchor.center,
      position: Vector2(center.x, center.y + 50),
      size: Vector2(100.0, 40.0),
      onTap: (_, __) => GameConfig.isDebugMode ? nextTurn() : startAutoBattle(),
    );
    world.add(nextTurnButton);
  }

  void _prepareBattle() async {
    heroTurn = initialMove;
    currentCharacter = heroTurn ? hero : enemy;
    currentOpponent = heroTurn ? enemy : hero;
    currentCharacter.addHintText('${engine.locale('attackFirstInBattle')}!');
  }

  Future<void> nextTurn() async {
    if (!battleEnded) {
      if (!battleStarted) {
        versusBanner.moveTo(
          duration: 0.3,
          toPosition: Vector2(center.x, center.y - 350),
        );
        _prepareBattle();
        nextTurnButton.text = engine.locale('nextTurn');
        battleStarted = true;

        final restartButton = SpriteButton(
          useSimpleStyle: true,
          text: engine.locale('restart'),
          priority: 5000,
          anchor: Anchor.center,
          position: center,
          size: Vector2(100.0, 40.0),
        );
        restartButton.onTap = (_, __) {
          _victoryPrompt.removeFromParent();
          _defeatPrompt.removeFromParent();
          battleEnded = false;
          battleResult = null;
          nextTurnButton.enableGesture = true;
          nextTurnButton.text = engine.locale('nextTurn');
          hero.reset();
          heroDeckZone.reset();
          enemy.reset();
          enemyDeckZone.reset();
          _prepareBattle();
          nextTurnButton.text = engine.locale('nextTurn');
          nextTurnButton.onTap = (_, __) => nextTurn();
          battleStarted = true;
        };

        world.add(restartButton);
      } else if (battleResult == null) {
        nextTurnButton.enableGesture = false;
        _startTurn();
      } else {
        _endBattle();
      }
    }
  }

  Future<void> _startTurn() async {
    GameCard card = currentCharacter.deckZone.current;

    bool extraTurn = false;
    do {
      final turnStartDetails =
          await currentCharacter.onTurnStart(card, isExtra: extraTurn);
      bool skipTurn = turnStartDetails['skipTurn'] ?? false;
      if (skipTurn) break;
      final turnEndDetails = await currentCharacter.onTurnEnd(card);
      extraTurn = turnEndDetails['extraTurn'] ?? false;
      card = currentCharacter.deckZone.nextCard();
    } while (extraTurn);

    heroTurn = !heroTurn;
    currentCharacter = heroTurn ? hero : enemy;
    currentOpponent = heroTurn ? enemy : hero;

    if (heroTurn == initialMove) {
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

    nextTurnButton.enableGesture = true;
  }

  void _endScene() {
    engine.emit('battleEnded', args: {'battleResult': battleResult});
  }

  void _endBattle() {
    if (battleResult == true) {
      world.add(_victoryPrompt);
    } else {
      world.add(_defeatPrompt);
    }

    // final heroName = '${hero.data['name']}(hero)';
    // final enemyName = '${enemy.data['name']}(enemy)';

    // engine.info(
    //     'battle between $heroName and $enemyName ended. ${battleResult! ? heroName : enemyName} won!');

    battleEnded = true;

    if (!nextTurnButton.isMounted) {
      world.add(nextTurnButton);
    }
    nextTurnButton.text = engine.locale('end');
    nextTurnButton.onTap = (_, __) => _endScene();
  }

  Future<void> startAutoBattle() async {
    nextTurnButton.removeFromParent();

    await versusBanner.moveTo(
      duration: 0.3,
      toPosition: Vector2(center.x, center.y - 275),
    );
    _prepareBattle();

    do {
      await _startTurn();
    } while (battleResult == null);

    _endBattle();
  }
}
