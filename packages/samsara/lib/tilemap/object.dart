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

class TileMapObject extends GameComponent with TileInfo {
  final String sceneKey;
  final bool isHero;
  final double velocityFactor;

  Sprite? sprite;
  bool _isAnimated = false;
  bool _hasOnWaterAnimation = false;
  late final SpriteAnimation? characterSouth,
      characterEast,
      characterNorth,
      characterWest,
      shipSouth,
      shipEast,
      shipNorth,
      shipWest;

  OrthogonalDirection direction = OrthogonalDirection.south;

  bool _isMoving = false;
  bool _isBackward = false;
  bool get isMoving => _isMoving;
  bool isMovingCanceled = false;

  bool isOnWater = false;
  Vector2 _movingOffset = Vector2.zero();
  Vector2 _movingTargetWorldPosition = Vector2.zero();
  TilePosition _movingTargetTilePosition = const TilePosition.leftTop();
  Vector2 _velocity = Vector2.zero();

  final SamsaraEngine engine;

  String? entityId;

  TileMapObject({
    required this.engine,
    required this.sceneKey,
    this.isHero = false,
    int? left,
    int? top,
    this.velocityFactor = 0.8,
    Sprite? sprite,
    SpriteSheet? animationSpriteSheet,
    SpriteSheet? waterAnimationSpriteSheet,
    required TileShape tileShape,
    required int tileMapWidth,
    required double gridWidth,
    required double gridHeight,
    required double srcWidth,
    required double srcHeight,
    double? offsetY,
    this.entityId,
  }) {
    if (animationSpriteSheet != null) {
      _isAnimated = true;
      characterSouth =
          animationSpriteSheet.createAnimation(row: 0, stepTime: 0.2);
      characterEast =
          animationSpriteSheet.createAnimation(row: 1, stepTime: 0.2);
      characterNorth =
          animationSpriteSheet.createAnimation(row: 2, stepTime: 0.2);
      characterWest =
          animationSpriteSheet.createAnimation(row: 3, stepTime: 0.2);

      if (waterAnimationSpriteSheet != null) {
        _hasOnWaterAnimation = true;

        shipSouth =
            waterAnimationSpriteSheet.createAnimation(row: 0, stepTime: 0.2);
        shipEast =
            waterAnimationSpriteSheet.createAnimation(row: 1, stepTime: 0.2);
        shipNorth =
            waterAnimationSpriteSheet.createAnimation(row: 2, stepTime: 0.2);
        shipWest =
            waterAnimationSpriteSheet.createAnimation(row: 3, stepTime: 0.2);
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
    this.offsetY = offsetY ?? 0.0;
    tilePosition = TilePosition(left ?? 1, top ?? 1);
  }

  void stopAnimation() {
    currentAnimation?.setToLast();
  }

  void stop() {
    tilePosition = _movingTargetTilePosition;
    _isMoving = false;
    // 广播事件中会检查英雄是否正在移动，因此这里要先取消移动，再广播
    // 检查isBackward的目的，是为了在英雄倒退到entity上时，不触发
    // 只有玩家自己主动经过某个entity，才触发事件
    if (isHero && !_isBackward) {
      engine.broadcast(HeroEvent.heroMoved(
        scene: sceneKey,
        tilePosition: tilePosition,
      ));
    }
    _isBackward = false;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition = Vector2.zero();
    _velocity = Vector2.zero();
    _movingTargetTilePosition = const TilePosition.leftTop();
  }

  void moveTo(TilePosition target, {bool backward = false}) {
    assert(tilePosition != target);
    _movingTargetTilePosition = target;
    _isMoving = true;
    _isBackward = backward;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition =
        tilePosition2TileCenterInWorld(target.left, target.top);
    direction = direction2Orthogonal(directionTo(target, backward: backward));

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
        case OrthogonalDirection.south:
          return shipSouth;
        case OrthogonalDirection.east:
          return shipEast;
        case OrthogonalDirection.west:
          return shipWest;
        case OrthogonalDirection.north:
          return shipNorth;
      }
    } else {
      switch (direction) {
        case OrthogonalDirection.south:
          return characterSouth;
        case OrthogonalDirection.east:
          return characterEast;
        case OrthogonalDirection.west:
          return characterWest;
        case OrthogonalDirection.north:
          return characterNorth;
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
  void render(Canvas canvas, {TilePosition? tilePosition}) {
    if (!isVisible) return;

    if (tilePosition != null) {
      this.tilePosition = tilePosition;
    }

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
