import 'dart:ui';

import 'package:flame/sprite.dart';

import '../game.dart';
import '../extensions.dart';
import 'tile.dart';
import 'tile_mixin.dart';
import '../shared/direction.dart';

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
  ActorDirection _direction = ActorDirection.south;
  set direction(Direction direction) {
    switch (direction) {
      case Direction.north:
        _direction = ActorDirection.north;
        break;
      case Direction.south:
        _direction = ActorDirection.south;
        break;
      case Direction.east:
      case Direction.northEast:
      case Direction.southEast:
        _direction = ActorDirection.east;
        break;
      case Direction.west:
      case Direction.northWest:
      case Direction.southWest:
        _direction = ActorDirection.west;
        break;
    }
  }

  bool isWalking = false;

  TileMapActor(
      {required SamsaraGame game,
      required this.characterId,
      required TileShape tileShape,
      required double gridWidth,
      required double gridHeight,
      required int left,
      required int top,
      required int index,
      required double srcWidth,
      required double srcHeight,
      required SpriteSheet spriteSheet})
      : south = spriteSheet.createAnimation(row: 0, stepTime: 0.2),
        east = spriteSheet.createAnimation(row: 1, stepTime: 0.2),
        north = spriteSheet.createAnimation(row: 2, stepTime: 0.2),
        west = spriteSheet.createAnimation(row: 3, stepTime: 0.2),
        super(game: game) {
    this.tileShape = tileShape;
    tilePosition = TilePosition(left, top);
    this.index = index;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
  }

  SpriteAnimation get currentAnimation {
    switch (_direction) {
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
