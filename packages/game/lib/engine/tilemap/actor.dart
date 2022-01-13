import 'dart:ui';

import 'package:flame/sprite.dart';

import '../game.dart';
import '../extensions.dart';
import 'tile.dart';
import 'tile_mixin.dart';

enum ActorDirection {
  south,
  east,
  west,
  north,
}

class TileMapActor extends GameComponent with TileInfo {
  final String characterId;

  bool get isHero => characterId == 'current';

  final SpriteAnimation south, east, west, north;
  final ActorDirection direction = ActorDirection.south;

  TileMapActor(
      {required SamsaraGame game,
      required this.characterId,
      required TileShape tileShape,
      required double gridWidth,
      required double gridHeight,
      required int left,
      required int top,
      required int srcWidth,
      required int srcHeight,
      required SpriteSheet spriteSheet})
      : south = spriteSheet.createAnimation(row: 0, stepTime: 0.2),
        east = spriteSheet.createAnimation(row: 1, stepTime: 0.2),
        west = spriteSheet.createAnimation(row: 2, stepTime: 0.2),
        north = spriteSheet.createAnimation(row: 3, stepTime: 0.2),
        super(game: game) {
    this.tileShape = tileShape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.left = left;
    this.top = top;
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
  }

  Sprite get currentSprite {
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
    final worldPos = tilePosition2World(left, top);
    currentSprite.render(canvas, position: worldPos);
  }
}
