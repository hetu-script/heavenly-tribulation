import 'dart:async';

import 'package:samsara/event.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:samsara/gestures.dart';

import '../common.dart';
import 'character.dart';
import 'deck_zone.dart';
import '../../../global.dart';
import 'status/status.dart';

class CardBattleScene extends Scene {
  final List<String> heroDeck;

  late final BattleCharacter hero, opponent;

  late final List<PlayingCard> heroCards, opponentCards;

  late final DeckZone heroDeckZone, opponentDeckZone;

  CardBattleScene({
    required super.controller,
    required String id,
    required this.heroDeck,
  }) : super(id: id);

  @override
  Future<void> onLoad() async {
    fitScreen(kGamepadSize);

    StatusEffect.registerEffect('block', (count) {
      return StatusEffect(
        id: 'block',
        title: 'block',
        description: 'block',
        spriteId: 'icon/status/block',
        count: count,
      );
    });

    final List<Sprite> charStandAnimSpriteList = [];
    for (var i = 0; i < 2; ++i) {
      final sprite = Sprite(await Flame.images
          .load('animation/fight/ns${(i + 1).toString().padLeft(2, '0')}.png'));
      charStandAnimSpriteList.add(sprite);
    }
    final standAnimation = SpriteAnimation.spriteList(
      charStandAnimSpriteList,
      stepTime: 0.7,
      loop: true,
    );

    final List<Sprite> charAttackAnimSpriteList = [];
    for (var i = 0; i < 13; ++i) {
      final sprite = Sprite(await Flame.images
          .load('animation/fight/nf${(i + 1).toString().padLeft(2, '0')}.png'));
      charAttackAnimSpriteList.add(sprite);
    }
    final attackAnimation = SpriteAnimation.spriteList(
      charAttackAnimSpriteList,
      stepTime: 0.07,
      loop: false,
    );

    hero = BattleCharacter(
      id: 'hero',
      standAnimation: standAnimation,
      attackAnimation: attackAnimation,
      size: kCharacterSize,
      life: 100,
      isHero: true,
    );
    add(hero);

    opponent = BattleCharacter(
      id: 'opponent',
      standAnimation: standAnimation.clone(),
      attackAnimation: attackAnimation.clone(),
      size: kCharacterSize,
      life: 100,
    );
    add(opponent);

    final List<PlayingCard> playerCards = [];
    for (final cardId in heroDeck) {
      final cardData = cardsData[cardId];
      final expansion = cardData['expansion'];
      String? spriteId = cardData['spriteId'];
      if (spriteId != null) {
        spriteId = expansion != null ? '$expansion/$spriteId' : spriteId;
      }
      assert(cardData != null);
      final card = PlayingCard(
        data: cardData,
        id: cardData['id'],
        deckId: cardData['name'],
        title: cardData['title'][engine.locale.languageId],
        description: cardData['rules'][engine.locale.languageId],
        frontSpriteId: spriteId,
        showTitle: true,
        titleStyle: const ScreenTextStyle(
          colorTheme: ScreenTextColorTheme.dark,
          anchor: Anchor.topLeft,
          padding: EdgeInsets.only(left: 12, top: 8),
        ),
        showDescription: true,
        size: kBattleCardSize,
        focusedPosition: Vector2(20, 100),
        focusedSize: kFocusedCardSize,
        // backSprite: cardBack,
      );
      playerCards.add(card);
      add(card);
    }

    final List<PlayingCard> opponentCards = [];
    for (var i = 0; i < 5; ++i) {
      final card = PlayingCard(
        id: 'template',
        deckId: 'template',
        frontSpriteId: 'basic/template',
        size: kBattleCardSize,
        focusedPosition: Vector2(20, 100),
        focusedSize: kFocusedCardSize,
        // backSprite: cardBack,
      );
      opponentCards.add(card);
      add(card);
    }

    heroDeckZone = DeckZone(
      id: 'player1DeckZone',
      position: kP1BattleDeckZonePosition,
      cards: playerCards,
      pileMargin: Vector2(10.0, 10.0),
      pileOffset: Vector2(50.0, 0.0),
    );
    add(heroDeckZone);
    heroDeckZone.sortCards(pileUp: false, animated: false);

    opponentDeckZone = DeckZone(
      id: 'player2DeckZone',
      position: kP2BattleDeckZonePosition,
      cards: opponentCards,
      pileMargin: Vector2(-10.0, 10.0),
      pileOffset: Vector2(-50.0, 0.0),
    );
    add(opponentDeckZone);
    opponentDeckZone.sortCards(pileUp: false, animated: false);
  }

  void characterTakeDamage(BattleCharacter character, double damage) {
    character.takeDamage(damage);

    if (character.isDefeated) {
      engine.broadcast(BattleEvent.ended(heroWon: !character.isHero));
    }
  }

  @override
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    heroDeckZone.nextCard(hero, opponent);
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
