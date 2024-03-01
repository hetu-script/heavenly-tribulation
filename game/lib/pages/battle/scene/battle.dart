import 'dart:async';

// import 'package:samsara/event.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/playing_card.dart';
// import 'package:samsara/gestures.dart';
import 'package:samsara/component/sprite_component.dart';
import 'package:flame/flame.dart';

import '../../../ui.dart';
import 'character.dart';
import 'deck_zone.dart';
import '../../../config.dart';
// import 'status/status.dart';
import 'versus_banner.dart';

class BattleScene extends Scene {
  late final SpriteComponent2 background;

  late final VersusBanner versusBanner;

  late final BattleCharacter hero, enemy;
  late final BattleDeck heroDeckZone, enemyDeckZone;
  final dynamic heroData, enemyData;
  final List<PlayingCard> heroCards, enemyCards;

  final bool isSneakAttack;

  int turn = 0;

  BattleScene({
    required super.controller,
    required super.id,
    required this.heroData,
    required this.enemyData,
    required this.heroCards,
    required this.enemyCards,
    required this.isSneakAttack,
  });

  bool isBattleEnded() {
    if (turn > 64 || enemy.life <= 0 || hero.life <= 0) return true;

    return false;
  }

  bool checkIfHeroFirst() {
    if (isSneakAttack) return true;

    final heroCP = heroData['cultivationPoints'];
    final enemyCP = enemyData['cultivationPoints'];

    if (heroCP > enemyCP) {
      return true;
    } else if (heroCP < enemyCP) {
      return false;
    } else {
      if (heroData['stats']['dexterity'] >= enemyData['stats']['dexterity']) {
        return true;
      } else {
        return false;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    fitScreen();

    background = SpriteComponent2(
      image: await Flame.images.load('battle/scene/bamboo.png'),
      size: size,
    );
    world.add(background);

    final heroSkinId = heroData['skin'];
    final Set<String> heroCardAnimations = {};
    for (final card in heroCards) {
      final states = card.data['animations'];
      for (final state in states) {
        heroCardAnimations.add('${state}_$heroSkinId');
      }
    }
    hero = BattleCharacter(
      position: GameUI.p1HeroSpritePosition,
      size: GameUI.heroSpriteSize,
      isHero: true,
      skinId: heroSkinId,
      cardAnimations: heroCardAnimations,
      data: heroData,
    );
    world.add(hero);

    heroDeckZone = BattleDeck(
      position: GameUI.p1BattleDeckZonePosition,
      cards: heroCards,
      focusedPosition: GameUI.p1BattleCardFocusedPosition,
      pileStructure: PileStructure.queue,
      reverseX: false,
    );
    world.add(heroDeckZone);

    final enemySkinId = enemyData['skin'];
    final Set<String> enemyCardAnimations = {};
    for (final card in heroCards) {
      final states = card.data['animations'];
      for (final state in states) {
        enemyCardAnimations.add('${state}_$enemySkinId');
      }
    }
    enemy = BattleCharacter(
      position: GameUI.p2HeroSpritePosition,
      size: GameUI.heroSpriteSize,
      skinId: enemySkinId,
      cardAnimations: enemyCardAnimations,
      data: enemyData,
    );
    world.add(enemy);

    enemyDeckZone = BattleDeck(
      position: GameUI.p2BattleDeckZonePosition,
      cards: enemyCards,
      focusedPosition: GameUI.p2BattleCardFocusedPosition,
      pileStructure: PileStructure.queue,
      reverseX: true,
    );
    world.add(enemyDeckZone);

    hero.opponent = enemy;
    enemy.opponent = hero;

    versusBanner = VersusBanner(
      priority: 5000,
      position: center,
      heroIconId: heroData['icon'],
      enemyIconId: enemyData['icon'],
    );
    world.add(versusBanner);
    showStartPrompt();
  }

  Future<void> showStartPrompt() async {
    await versusBanner.fadeIn(duration: 1.2);
    await versusBanner.moveTo(
      duration: 0.3,
      toPosition: Vector2(center.x, center.y - 350),
    );
    battleLoop();
  }

  Future<void> battleLoop() async {
    bool heroMove = checkIfHeroFirst();

    while (!isBattleEnded()) {
      final card = heroMove
          ? await heroDeckZone.nextCard()
          : await enemyDeckZone.nextCard();

      assert(card.script != null);
      await engine.hetu.invoke(
        card.script!,
        namespace: 'Card',
        positionalArgs: [heroMove ? hero : enemy, heroMove ? enemy : hero],
      );

      heroMove = !heroMove;
      await card.setFocused(false);
    }

    engine.info('battle ended!');
  }
}
