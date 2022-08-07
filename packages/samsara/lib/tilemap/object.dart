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
  static const defaultAnimationStepTime = 0.2;

  final String sceneKey;
  final bool isHero;
  final double velocityFactor;

  Sprite? sprite;
  SpriteAnimation? animation;
  bool _isMovingObject = false;
  bool _hasMoveOnWaterAnimation = false;
  late final SpriteAnimation? moveAnimSouth,
      moveAnimEast,
      moveAnimNorth,
      moveAnimWest,
      moveOnWaterAnimSouth,
      moveOnWaterAnimEast,
      moveOnWaterAnimNorth,
      moveOnWaterAnimWest;

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
    SpriteAnimation? animation,
    SpriteSheet? moveAnimationSpriteSheet,
    SpriteSheet? moveOnWaterAnimationSpriteSheet,
    required TileShape tileShape,
    required int tileMapWidth,
    required double gridWidth,
    required double gridHeight,
    required double srcWidth,
    required double srcHeight,
    double srcOffsetY = 0.0,
    this.entityId,
  }) {
    if (moveAnimationSpriteSheet != null) {
      _isMovingObject = true;
      moveAnimSouth = moveAnimationSpriteSheet.createAnimation(
          row: 0, stepTime: defaultAnimationStepTime);
      moveAnimEast = moveAnimationSpriteSheet.createAnimation(
          row: 1, stepTime: defaultAnimationStepTime);
      moveAnimNorth = moveAnimationSpriteSheet.createAnimation(
          row: 2, stepTime: defaultAnimationStepTime);
      moveAnimWest = moveAnimationSpriteSheet.createAnimation(
          row: 3, stepTime: defaultAnimationStepTime);

      if (moveOnWaterAnimationSpriteSheet != null) {
        _hasMoveOnWaterAnimation = true;

        moveOnWaterAnimSouth = moveOnWaterAnimationSpriteSheet.createAnimation(
            row: 0, stepTime: defaultAnimationStepTime);
        moveOnWaterAnimEast = moveOnWaterAnimationSpriteSheet.createAnimation(
            row: 1, stepTime: defaultAnimationStepTime);
        moveOnWaterAnimNorth = moveOnWaterAnimationSpriteSheet.createAnimation(
            row: 2, stepTime: defaultAnimationStepTime);
        moveOnWaterAnimWest = moveOnWaterAnimationSpriteSheet.createAnimation(
            row: 3, stepTime: defaultAnimationStepTime);
      }
    } else {
      _isMovingObject = false;
      if (sprite != null) {
        this.sprite = sprite;
      } else {
        assert(animation != null);
        this.animation = animation;
      }
    }

    this.tileMapWidth = tileMapWidth;
    this.tileShape = tileShape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
    this.srcOffsetY = srcOffsetY;
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
    if (_hasMoveOnWaterAnimation && isOnWater) {
      switch (direction) {
        case OrthogonalDirection.south:
          return moveOnWaterAnimSouth;
        case OrthogonalDirection.east:
          return moveOnWaterAnimEast;
        case OrthogonalDirection.west:
          return moveOnWaterAnimWest;
        case OrthogonalDirection.north:
          return moveOnWaterAnimNorth;
      }
    } else {
      switch (direction) {
        case OrthogonalDirection.south:
          return moveAnimSouth;
        case OrthogonalDirection.east:
          return moveAnimEast;
        case OrthogonalDirection.west:
          return moveAnimWest;
        case OrthogonalDirection.north:
          return moveAnimNorth;
      }
    }
  }

  Sprite getSprite() {
    if (_isMovingObject) {
      return currentAnimation!.getSprite();
    } else {
      if (animation != null) {
        return animation!.getSprite();
      } else {
        return sprite!;
      }
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
