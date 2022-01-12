import 'dart:ui';

import 'package:flame/sprite.dart';
import '../game.dart';

import '../extensions.dart';

enum ActorDirection {
  south,
  east,
  west,
  north,
}

class TileMapActor extends GameComponent {
  final int left, top;
  final int srcWidth, srcHeight;

  final SpriteAnimation south, east, west, north;
  final ActorDirection direction = ActorDirection.south;

  final String characterId;

  TileMapActor(
      {required SamsaraGame game,
      required this.left,
      required this.top,
      required this.srcWidth,
      required this.srcHeight,
      required this.characterId,
      required SpriteSheet sheet})
      : south = sheet.createAnimation(row: 0, stepTime: 0.2),
        east = sheet.createAnimation(row: 1, stepTime: 0.2),
        west = sheet.createAnimation(row: 2, stepTime: 0.2),
        north = sheet.createAnimation(row: 3, stepTime: 0.2),
        super(game: game);

  Sprite get _currentSprite {
    switch (direction) {
      case ActorDirection.south:
        return south.getSprite();
      case ActorDirection.east:
        return east.getSprite();
      case ActorDirection.west:
        return west.getSprite();
      case ActorDirection.north:
        return north.getSprite();
    }
  }

  @override
  void render(Canvas canvas) {
    _currentSprite.render(canvas, position: position);
  }
}
