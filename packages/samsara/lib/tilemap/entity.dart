import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../component/game_component.dart';
import 'tile.dart';
import '../shared/direction.dart';
import '../engine.dart';
import '../../event/events.dart';

enum AnimationDirection {
  south,
  east,
  west,
  north,
}

class TileMapEntity extends GameComponent with TileInfo {
  final bool isHero;
  final double velocityFactor;

  Sprite? sprite;
  bool _isAnimated = false;
  bool _hasOnWaterAnimation = false;
  late final SpriteAnimation? characterSouth,
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
  bool isOnWater = false;
  Vector2 _movingOffset = Vector2.zero();
  Vector2 _movingTargetWorldPosition = Vector2.zero();
  TilePosition _movingTargetTilePosition = const TilePosition.leftTop();
  Vector2 _velocity = Vector2.zero();

  final SamsaraEngine engine;

  String? entityIndex;

  TileMapEntity({
    required this.engine,
    this.isHero = false,
    int left = 1,
    int top = 1,
    this.velocityFactor = 0.5,
    Sprite? sprite,
    SpriteSheet? animationSpriteSheet,
    SpriteSheet? waterAnimationSpriteSheet,
    required TileShape tileShape,
    required int tileMapWidth,
    required double gridWidth,
    required double gridHeight,
    required double srcWidth,
    required double srcHeight,
    this.entityIndex,
  }) {
    if (animationSpriteSheet != null) {
      _isAnimated = true;
      characterSouth =
          animationSpriteSheet.createAnimation(row: 0, stepTime: 0.2);
      characterNorthEast =
          animationSpriteSheet.createAnimation(row: 1, stepTime: 0.2);
      characterSouthEast =
          animationSpriteSheet.createAnimation(row: 2, stepTime: 0.2);
      characterNorth =
          animationSpriteSheet.createAnimation(row: 3, stepTime: 0.2);
      characterNorthWest =
          animationSpriteSheet.createAnimation(row: 4, stepTime: 0.2);
      characterSouthWest =
          animationSpriteSheet.createAnimation(row: 5, stepTime: 0.2);

      if (waterAnimationSpriteSheet != null) {
        _hasOnWaterAnimation = true;

        shipSouth =
            waterAnimationSpriteSheet.createAnimation(row: 0, stepTime: 0.2);
        shipNorthEast =
            waterAnimationSpriteSheet.createAnimation(row: 1, stepTime: 0.2);
        shipSouthEast =
            waterAnimationSpriteSheet.createAnimation(row: 2, stepTime: 0.2);
        shipNorth =
            waterAnimationSpriteSheet.createAnimation(row: 3, stepTime: 0.2);
        shipNorthWest =
            waterAnimationSpriteSheet.createAnimation(row: 4, stepTime: 0.2);
        shipSouthWest =
            waterAnimationSpriteSheet.createAnimation(row: 5, stepTime: 0.2);
      }
    } else {
      assert(sprite != null);
      this.sprite = sprite;
    }

    this.tileMapWidth = tileMapWidth;
    this.tileShape = tileShape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
    tilePosition = TilePosition(left, top);
  }

  void stop() {
    currentAnimation?.setToLast();
    _isMoving = false;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition = Vector2.zero();
    _velocity = Vector2.zero();
    tilePosition = _movingTargetTilePosition;
    _movingTargetTilePosition = const TilePosition.leftTop();
    if (isHero) {
      engine.broadcast(const HeroEvent.heroMoved());
    }
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

  SpriteAnimation? get currentAnimation {
    if (_hasOnWaterAnimation && isOnWater) {
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

  Sprite getSprite() {
    if (_isAnimated) {
      return currentAnimation!.getSprite();
    } else {
      return sprite!;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    var rpos = renderPosition;
    if (isMoving) {
      rpos += _movingOffset;
    }
    getSprite().render(canvas, position: rpos);
  }

  @override
  void update(double dt) {
    if (isMoving) {
      currentAnimation?.update(dt);
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
