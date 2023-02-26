import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/paint/paint.dart';

import '../../../global.dart';
import '../common.dart';
import 'deck_zone.dart';
import 'character.dart';

class PlayGround extends GameComponent with HandlesGesture {
  late final DeckZone player1DeckZone, player2DeckZone;

  final FightSceneCharacter player1Char, player2Char;

  PlayGround({
    required double width,
    required double height,
    required this.player1Char,
    required this.player2Char,
  }) : super(size: Vector2(width, height));

  void centerGame() {
    final gameViewPortSize = gameRef.size;
    engine.info('游戏界面可视区域大小：${gameViewPortSize.x}x${gameViewPortSize.y}');
    final padRatio = width / height;
    final sizeRatio = gameViewPortSize.x / gameViewPortSize.y;
    if (sizeRatio > padRatio) {
      // 可视区域更宽
      final scaleFactor = gameViewPortSize.y / height;
      scale = Vector2(scaleFactor, scaleFactor);
      final newWidth = width * scaleFactor;
      x = (gameViewPortSize.x - newWidth) / 2;
    } else {
      // 可视区域更窄
      final scaleFactor = gameViewPortSize.y / height;
      scale = Vector2(scaleFactor, scaleFactor);
      final newHeight = height * scaleFactor;
      y = (gameViewPortSize.y - newHeight) / 2;
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    centerGame();

    final List<PlayingCard> player1Cards = [];
    for (var i = 0; i < 5; ++i) {
      final card = PlayingCard(
        frontSpriteId: 'template',
        width: kCardWidth,
        height: kCardHeight,
        focusedPosition: Vector2(20, 100),
        focusedSize: kFocusedCardSize,
      );
      player1Cards.add(card);
      add(card);
    }

    player1DeckZone = DeckZone(
      id: 'player1DeckZone',
      x: kPlayer1DeckZoneLeft,
      y: kPlayer1DeckZoneTop,
      cards: player1Cards,
    );
    add(player1DeckZone);

    player2DeckZone = DeckZone(
      id: 'player2DeckZone',
      x: kPlayer2DeckZoneLeft,
      y: kPlayer2DeckZoneTop,
    );
    add(player2DeckZone);
  }

  @override
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    player1DeckZone.setNextCardFocused();

    super.onTapUp(pointer, buttons, details);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, borderPaint);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    gameRef.camera.snapTo(gameRef.camera.position - details.delta.toVector2());

    super.onDragUpdate(pointer, buttons, details);
  }
}
