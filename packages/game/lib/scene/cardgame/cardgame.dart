import 'package:samsara/samsara.dart';
import 'package:samsara/utils/uid.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import 'components/playground.dart';
import 'common.dart';
import 'components/character.dart';

class CardGameScene extends Scene {
  CardGameScene({
    required super.controller,
  }) : super(name: 'cardGame', key: 'cardGame${uid4()}');

  @override
  Future<void> onLoad() async {
    super.onLoad();

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

    final player1Char = FightSceneCharacter(
      id: 'player1Char',
      standAnimation: standAnimation,
      attackAnimation: attackAnimation,
    );
    add(player1Char);

    final player2Char = FightSceneCharacter(
      id: 'player2Char',
      standAnimation: standAnimation.clone(),
      attackAnimation: attackAnimation.clone(),
    );
    player2Char.flipHorizontally();
    player2Char.x = 1280;
    add(player2Char);

    final p = PlayGround(
      width: kGamepadSize.x,
      height: kGamepadSize.y,
      player1Char: player1Char,
      player2Char: player2Char,
    );
    add(p);
  }

  // @override
  // void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
  //   camera.snapTo(camera.position - details.delta.toVector2());

  //   super.onDragUpdate(pointer, buttons, details);
  // }
}
