import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/event.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:samsara/game_ui/progress_indicator.dart';

import 'common.dart';
import 'cardgame/character.dart';
import 'cardgame/deck_zone.dart';
import '../../global.dart';

class CardGameAutoBattlerScene extends Scene {
  final Map<String, dynamic> arg;

  late final FightSceneCharacter p1Char, p2Char;

  late final DynamicColorProgressIndicator p1HealthBar, p2HealthBar;

  late final List<PlayingCard> p1Cards, p2Cards;

  late final DeckZone p1DeckZone, p2DeckZone;

  CardGameAutoBattlerScene({
    required super.controller,
    required this.arg,
  }) : super(id: arg['id']);

  @override
  Future<void> onLoad() async {
    fitScreen(kGamepadSize);

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

    p1Char = FightSceneCharacter(
      id: 'player1Char',
      standAnimation: standAnimation,
      attackAnimation: attackAnimation,
      width: kCharacterWidth,
      height: kCharacterHeight,
      life: 100,
      onTakeDamage: (life) {
        p1HealthBar.value = life;
      },
      isHero: true,
    );
    add(p1Char);

    p1HealthBar = DynamicColorProgressIndicator(
      x: (kCharacterWidth - 100) / 2,
      y: p1Char.center.y - 160,
      width: 100,
      height: 10,
      value: 100,
      max: 100,
      colors: [Colors.red, Colors.green],
      showNumber: true,
    );
    add(p1HealthBar);

    p2Char = FightSceneCharacter(
      id: 'player2Char',
      standAnimation: standAnimation.clone(),
      attackAnimation: attackAnimation.clone(),
      width: kCharacterWidth,
      height: kCharacterHeight,
      life: 100,
      onTakeDamage: (life) {
        p2HealthBar.value = life;
      },
    );
    p2Char.flipHorizontally();
    p2Char.x = kGamepadSize.x;
    add(p2Char);

    p2HealthBar = DynamicColorProgressIndicator(
      x: (kGamepadSize.x - kCharacterWidth) + (kCharacterWidth - 100) / 2,
      y: p2Char.center.y - 160,
      width: 100,
      height: 10,
      value: 100,
      max: 100,
      colors: [Colors.red, Colors.green],
      showNumber: true,
    );
    add(p2HealthBar);

    final List<PlayingCard> player1Cards = [];
    for (var i = 0; i < 5; ++i) {
      final card = PlayingCard(
        frontSpriteId: 'basic/template',
        size: kBattleCardSize,
        focusedPosition: Vector2(20, 100),
        focusedSize: kFocusedCardSize,
        // backSprite: cardBack,
      );
      player1Cards.add(card);
      add(card);
    }

    final List<PlayingCard> player2Cards = [];
    for (var i = 0; i < 5; ++i) {
      final card = PlayingCard(
        frontSpriteId: 'basic/template',
        size: kBattleCardSize,
        focusedPosition: Vector2(20, 100),
        focusedSize: kFocusedCardSize,
        // backSprite: cardBack,
      );
      player2Cards.add(card);
      add(card);
    }

    p1DeckZone = DeckZone(
      id: 'player1DeckZone',
      position: kP1BattleDeckZonePosition,
      cards: player1Cards,
    );
    add(p1DeckZone);
    p1DeckZone.sortCards(pileUp: false);

    p2DeckZone = DeckZone(
      id: 'player2DeckZone',
      position: kP2BattleDeckZonePosition,
      cards: player2Cards,
      pileMargin: Vector2(-10.0, 10.0),
      pileOffset: Vector2(-50.0, 0.0),
    );
    add(p2DeckZone);
    p2DeckZone.sortCards(pileUp: false);
  }

  void characterTakeDamage(FightSceneCharacter character, double damage) {
    character.takeDamage(damage: damage);

    if (character.isDefeated) {
      engine.broadcast(BattleEvent.ended(heroWon: !character.isHero));
    }
  }

  @override
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    // player1DeckZone.setNextCardFocused();
    characterTakeDamage(p2Char, 7);

    super.onTapUp(pointer, buttons, details);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.snapTo(camera.position - details.delta.toVector2());

    super.onDragUpdate(pointer, buttons, details);
  }
}
