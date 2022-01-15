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

  bool isWalking = false;

  TileMapActor(
      {required SamsaraGame game,
      required this.characterId,
      required TileShape tileShape,
      required double gridWidth,
      required double gridHeight,
      required int left,
      required int top,
      required double srcWidth,
      required double srcHeight,
      required SpriteSheet spriteSheet})
      : south = spriteSheet.createAnimation(row: 0, stepTime: 0.2),
        east = spriteSheet.createAnimation(row: 1, stepTime: 0.2),
        west = spriteSheet.createAnimation(row: 2, stepTime: 0.2),
        north = spriteSheet.createAnimation(row: 3, stepTime: 0.2),
        super(game: game) {
    this.tileShape = tileShape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    tilePosition = TilePosition(left, top);
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
  }

  SpriteAnimation get currentAnimation {
    switch (direction) {
      case ActorDirection.south:
        return south;
      case ActorDirection.east:
        return east;
      case ActorDirection.west:
        return west;
      case ActorDirection.north:
        return north;
    }
  }

  @override
  void render(Canvas canvas) {
    final worldPos = tilePosition2World(left, top);
    currentAnimation.getSprite().render(canvas, position: worldPos);
  }

  @override
  void update(double dt) {
    if (isWalking) {
      currentAnimation.update(dt);
    }
  }
}
