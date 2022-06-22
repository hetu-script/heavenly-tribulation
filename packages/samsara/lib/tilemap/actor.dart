import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../component/game_component.dart';
import 'tile.dart';
import 'tile_mixin.dart';
import '../shared/direction.dart';
import '../engine.dart';
import '../../event/events.dart';

enum AnimationDirection {
  south,
  east,
  west,
  north,
}

class TileMapActor extends GameComponent with TileInfo {
  final double velocityFactor;

  final String characterId;

  bool get isHero => characterId == 'current';

  final SpriteAnimation characterSouth,
      characterNorthEast,
      characterSouthEast,
      characterNorth,
      characterNorthWest,
      characterSouthWest,
      shipSouth,
      shipNorthEast,
      shipSouthEast,
      shipNorth,
      shipNorthWest,
      shipSouthWest;
  HexagonalDirection direction = HexagonalDirection.south;

  bool _isMoving = false;
  bool get isMoving => _isMoving;
  bool isOnShip = false;
  Vector2 _movingOffset = Vector2.zero();
  Vector2 _movingTargetWorldPosition = Vector2.zero();
  TilePosition _movingTargetTilePosition = const TilePosition.zero();
  Vector2 _velocity = Vector2.zero();

  final SamsaraEngine engine;

  void stop() {
    _isMoving = false;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition = Vector2.zero();
    _velocity = Vector2.zero();
    tilePosition = _movingTargetTilePosition;
    _movingTargetTilePosition = const TilePosition.zero();
    engine.broadcast(const MapInteractionEvent.heroMoved());
  }

  void moveTo(TilePosition target) {
    assert(tilePosition != target);
    _movingTargetTilePosition = target;
    _isMoving = true;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition =
        tilePosition2TileCenterInWorld(target.left, target.top);
    direction = direction2Hexagonal(directionTo(target));

    // 计算地图上的斜方向实际距离
    final sx = _movingTargetWorldPosition.x - worldPosition.x;
    final sy = _movingTargetWorldPosition.y - worldPosition.y;
    final dx = sx.abs();
    final dy = sy.abs();
    final d = math.sqrt(dx * dx + dy * dy);
    final t = d / velocityFactor;
    final tx = dx / t;
    final ty = dy / t;
    _velocity = Vector2(tx * sx.sign, ty * sy.sign);
  }

  TileMapActor(
      {required this.engine,
      required this.characterId,
      required TileShape shape,
      required double gridWidth,
      required double gridHeight,
      required int left,
      required int top,
      required int tileMapWidth,
      required double srcWidth,
      required double srcHeight,
      required SpriteSheet characterAnimationSpriteSheet,
      required SpriteSheet shipAnimationSpriteSheet,
      this.velocityFactor = 0.5})
      : characterSouth = characterAnimationSpriteSheet.createAnimation(
            row: 0, stepTime: 0.2),
        characterNorthEast = characterAnimationSpriteSheet.createAnimation(
            row: 1, stepTime: 0.2),
        characterSouthEast = characterAnimationSpriteSheet.createAnimation(
            row: 2, stepTime: 0.2),
        characterNorth = characterAnimationSpriteSheet.createAnimation(
            row: 3, stepTime: 0.2),
        characterNorthWest = characterAnimationSpriteSheet.createAnimation(
            row: 4, stepTime: 0.2),
        characterSouthWest = characterAnimationSpriteSheet.createAnimation(
            row: 5, stepTime: 0.2),
        shipSouth =
            shipAnimationSpriteSheet.createAnimation(row: 0, stepTime: 0.2),
        shipNorthEast =
            shipAnimationSpriteSheet.createAnimation(row: 1, stepTime: 0.2),
        shipSouthEast =
            shipAnimationSpriteSheet.createAnimation(row: 2, stepTime: 0.2),
        shipNorth =
            shipAnimationSpriteSheet.createAnimation(row: 3, stepTime: 0.2),
        shipNorthWest =
            shipAnimationSpriteSheet.createAnimation(row: 4, stepTime: 0.2),
        shipSouthWest =
            shipAnimationSpriteSheet.createAnimation(row: 5, stepTime: 0.2) {
    this.tileMapWidth = tileMapWidth;
    this.shape = shape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
    tilePosition = TilePosition(left, top);
  }

  SpriteAnimation get currentAnimation {
    if (isOnShip) {
      switch (direction) {
        case HexagonalDirection.south:
          return shipSouth;
        case HexagonalDirection.northEast:
          return shipNorthEast;
        case HexagonalDirection.southEast:
          return shipSouthEast;
        case HexagonalDirection.north:
          return shipNorth;
        case HexagonalDirection.northWest:
          return shipNorthWest;
        case HexagonalDirection.southWest:
          return shipSouthWest;
      }
    } else {
      switch (direction) {
        case HexagonalDirection.south:
          return characterSouth;
        case HexagonalDirection.northEast:
          return characterNorthEast;
        case HexagonalDirection.southEast:
          return characterSouthEast;
        case HexagonalDirection.north:
          return characterNorth;
        case HexagonalDirection.northWest:
          return characterNorthWest;
        case HexagonalDirection.southWest:
          return characterSouthWest;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    var rpos = renderPosition;
    if (isMoving) {
      rpos += _movingOffset;
    }
    currentAnimation.getSprite().render(canvas, position: rpos);
  }

  @override
  void update(double dt) {
    if (isMoving) {
      currentAnimation.update(dt);
      _movingOffset.x += _velocity.x;
      _movingOffset.y += _velocity.y;

      final currentPosition = worldPosition + _movingOffset;
      if (_movingTargetWorldPosition.y < worldPosition.y &&
          currentPosition.y < _movingTargetWorldPosition.y) {
        stop();
      } else if (_movingTargetWorldPosition.y > worldPosition.y &&
          currentPosition.y > _movingTargetWorldPosition.y) {
        stop();
      } else if (_movingTargetWorldPosition.x < worldPosition.x &&
          currentPosition.x < _movingTargetWorldPosition.x) {
        stop();
      } else if (_movingTargetWorldPosition.x > worldPosition.x &&
          currentPosition.x > _movingTargetWorldPosition.x) {
        stop();
      }
    }
  }
}
