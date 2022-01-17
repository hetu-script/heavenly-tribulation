import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../extensions.dart';
import 'tile.dart';
import 'tile_mixin.dart';
import '../shared/direction.dart';

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

  final SpriteAnimation south, east, west, north;
  AnimationDirection _animationDirection = AnimationDirection.south;
  set direction(Direction direction) {
    switch (direction) {
      case Direction.north:
      case Direction.northEast:
        _animationDirection = AnimationDirection.north;
        break;
      case Direction.east:
      case Direction.southEast:
        _animationDirection = AnimationDirection.east;
        break;
      case Direction.south:
      case Direction.southWest:
        _animationDirection = AnimationDirection.south;
        break;
      case Direction.west:
      case Direction.northWest:
        _animationDirection = AnimationDirection.west;
        break;
    }
  }

  bool _isMoving = false;
  bool get isMoving => _isMoving;
  Vector2 _movingOffset = Vector2.zero();
  Vector2 _movingTargetWorldPosition = Vector2.zero();
  TilePosition _movingTargetTilePosition = const TilePosition.zero();
  Vector2 _velocity = Vector2.zero();

  void stop() {
    _isMoving = false;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition = Vector2.zero();
    _velocity = Vector2.zero();
    tilePosition = _movingTargetTilePosition;
    _movingTargetTilePosition = const TilePosition.zero();
  }

  void moveTo(TilePosition target) {
    assert(tilePosition != target);
    _movingTargetTilePosition = target;
    _isMoving = true;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition =
        tilePosition2TileCenterInWorld(target.left, target.top);
    direction = directionTo(target);

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
      {required this.characterId,
      required TileShape shape,
      required double gridWidth,
      required double gridHeight,
      required int left,
      required int top,
      required int tileMapWidth,
      required double srcWidth,
      required double srcHeight,
      required SpriteSheet spriteSheet,
      this.velocityFactor = 0.5})
      : south = spriteSheet.createAnimation(row: 0, stepTime: 0.2),
        east = spriteSheet.createAnimation(row: 1, stepTime: 0.2),
        north = spriteSheet.createAnimation(row: 2, stepTime: 0.2),
        west = spriteSheet.createAnimation(row: 3, stepTime: 0.2) {
    this.tileMapWidth = tileMapWidth;
    this.shape = shape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
    tilePosition = TilePosition(left, top);
  }

  SpriteAnimation get currentAnimation {
    switch (_animationDirection) {
      case AnimationDirection.south:
        return south;
      case AnimationDirection.east:
        return east;
      case AnimationDirection.west:
        return west;
      case AnimationDirection.north:
        return north;
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
