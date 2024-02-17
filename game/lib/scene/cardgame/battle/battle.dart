import 'dart:async';

// import 'package:samsara/event.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/component/sprite_component.dart';
import 'package:flame/flame.dart';

import '../common.dart';
import 'character.dart';
import 'deck_zone.dart';
// import '../../../global.dart';
// import 'status/status.dart';

class BattleScene extends Scene {
  late final SpriteComponent2 background;

  late final BattleCharacter hero, enemy;

  late final DeckZone heroDeckZone, enemyDeckZone;

  final List<PlayingCard> heroCards, enemyCards;

  BattleScene({
    required super.controller,
    required super.id,
    required this.heroCards,
    required this.enemyCards,
  }) {
    // StatusEffect.registerEffect('block', (count) {
    //   return StatusEffect(
    //     id: 'block',
    //     title: 'block',
    //     description: 'block',
    //     spriteId: 'icon/status/block',
    //     count: count,
    //   );
    // });
  }

  @override
  Future<void> onLoad() async {
    fitScreen();

    // fitScreen(kGamepadSize);
    background = SpriteComponent2(
      image: await Flame.images.load('battle/scene/bamboo.png'),
      size: kGamepadSize,
    );
    world.add(background);

    hero = BattleCharacter(
      id: 'hero',
      size: kHeroSize,
      life: 100,
      isHero: true,
    );
    world.add(hero);

    heroDeckZone = DeckZone(
      id: 'player1DeckZone',
      position: kP1BattleDeckZonePosition,
      cards: heroCards,
      pileMargin: Vector2(10.0, 10.0),
      pileOffset: Vector2(50.0, 0.0),
    );
    world.add(heroDeckZone);
    heroDeckZone.sortCards(pileUp: false, animated: false);

    // enemyDeckZone = DeckZone(
    //   id: 'player2DeckZone',
    //   position: kP2BattleDeckZonePosition,
    //   cards: enemyCards,
    //   pileMargin: Vector2(-10.0, 10.0),
    //   pileOffset: Vector2(-50.0, 0.0),
    // );
    // world.add(enemyDeckZone);
    // enemyDeckZone.sortCards(pileUp: false, animated: false);
  }

  void characterTakeDamage(BattleCharacter character, double damage) {
    character.takeDamage(damage);

    if (character.isDefeated) {
      // engine.emit(BattleEvent.ended(heroWon: !character.isHero));
    }
  }

  @override
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    heroDeckZone.nextCard(hero, enemy);
    // characterTakeDamage(p2Char, 7);

    // hero.status.addEffect('block', 5);

    super.onTapUp(pointer, buttons, details);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.snapTo(camera.position - details.delta.toVector2());

    super.onDragUpdate(pointer, buttons, details);
  }
}
