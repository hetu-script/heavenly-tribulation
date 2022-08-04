import 'package:quiver/core.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../component/game_component.dart';
import '../shared/direction.dart';

const _kCaptionOffset = 14.0;

class TilePosition {
  final int left, top;

  const TilePosition(this.left, this.top);
  const TilePosition.leftTop() : this(1, 1);

  @override
  String toString() => '[$left,$top]';

  @override
  int get hashCode {
    return hashObjects([left, top]);
  }

  @override
  bool operator ==(Object other) {
    if (other is TilePosition) {
      return hashCode == other.hashCode;
    }
    return false;
  }
}

enum TileShape {
  orthogonal,
  isometric,
  hexagonalVertical,
  hexagonalHorizontal,
}

enum TileRenderDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  bottomCenter,
}

const kZoneCategoryContinent = 'continent';
const kZoneCategoryIsland = 'island';
const kZoneCategoryLake = 'lake';
const kZoneCategorySea = 'sea';

class TileMapTerrain extends GameComponent with TileInfo {
  static const defaultAnimationStepTime = 0.4;

  static final borderPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = Colors.blue;

  /// internal data of this tile, possible json or other user-defined data form.
  final dynamic data;

  final borderPath = Path();
  final shadowPath = Path();
  late Rect rect;

  final SpriteAnimation? baseAnimation, overlayAnimation;
  final double offsetX, offsetY;

  // final TileRenderDirection renderDirection;

  final String? kind;

  bool isWater;

  final String? nationId;
  final String? locationId;
  final TextPaint _captionPaint;

  bool isSelectable;

  bool isVoid;

  // 显示标签
  String? caption;
  // 显示物体
  String? objectId;
  // 显示贴图
  Sprite? sprite, overlaySprite;

  TileMapTerrain({
    required TileShape tileShape,
    // this.renderDirection = TileRenderDirection.bottomRight,
    this.data,
    required int left,
    required int top,
    bool isVisible = true,
    this.isSelectable = false,
    this.isVoid = false,
    required int tileMapWidth,
    required double srcWidth,
    required double srcHeight,
    required double gridWidth,
    required double gridHeight,
    required this.isWater,
    required this.kind,
    this.nationId,
    this.locationId,
    this.caption,
    required TextStyle captionStyle,
    this.sprite,
    this.baseAnimation,
    this.overlaySprite,
    this.overlayAnimation,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.objectId,
  }) : _captionPaint = TextPaint(
          style: captionStyle.copyWith(
            fontSize: 7.0,
            shadows: const [
              Shadow(
                  // bottomLeft
                  offset: Offset(-0.5, -0.5),
                  color: Colors.black),
              Shadow(
                  // bottomRight
                  offset: Offset(0.5, -0.5),
                  color: Colors.black),
              Shadow(
                  // topRight
                  offset: Offset(0.5, 0.5),
                  color: Colors.black),
              Shadow(
                  // topLeft
                  offset: Offset(-0.5, 0.5),
                  color: Colors.black),
            ],
          ),
        ) {
    this.tileMapWidth = tileMapWidth;
    this.tileShape = tileShape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = width = srcWidth;
    this.srcHeight = height = srcHeight;
    tilePosition = TilePosition(left, top);
    generateRect();
    this.isVisible = isVisible;
  }

  void generateRect() {
    double bleendingPixelHorizontal = width * 0.04;
    double bleendingPixelVertical = height * 0.04;
    if (bleendingPixelHorizontal > 2) {
      bleendingPixelHorizontal = 2;
    }
    if (bleendingPixelVertical > 2) {
      bleendingPixelVertical = 2;
    }

    late final double l, t; // l, t,
    switch (tileShape) {
      case TileShape.orthogonal:
        l = ((left - 1) * gridWidth);
        t = ((top - 1) * gridHeight);
        final border = Rect.fromLTWH(l, t, gridWidth, gridHeight);
        borderPath.addRect(border);
        break;
      case TileShape.hexagonalVertical:
        l = (left - 1) * gridWidth * (3 / 4);
        t = left.isOdd
            ? (top - 1) * gridHeight
            : (top - 1) * gridHeight + gridHeight / 2;
        borderPath.moveTo(l, t + gridHeight / 2);
        borderPath.relativeLineTo(gridWidth / 4, -gridHeight / 2);
        borderPath.relativeLineTo(gridWidth / 2, 0);
        borderPath.relativeLineTo(gridWidth / 4, gridHeight / 2);
        borderPath.relativeLineTo(-gridWidth / 4, gridHeight / 2);
        borderPath.relativeLineTo(-gridWidth / 2, 0);
        borderPath.relativeLineTo(-gridWidth / 4, -gridHeight / 2);
        shadowPath.moveTo(l - bleendingPixelHorizontal + offsetX,
            t + gridHeight / 2 + offsetX);
        shadowPath.relativeLineTo(gridWidth / 4 + bleendingPixelHorizontal,
            -gridHeight / 2 - bleendingPixelVertical);
        shadowPath.relativeLineTo(gridWidth / 2, 0);
        shadowPath.relativeLineTo(gridWidth / 4 + bleendingPixelHorizontal,
            gridHeight / 2 + bleendingPixelVertical);
        shadowPath.relativeLineTo(-gridWidth / 4 - bleendingPixelHorizontal,
            gridHeight / 2 + bleendingPixelVertical);
        shadowPath.relativeLineTo(-gridWidth / 2, 0);
        shadowPath.relativeLineTo(-gridWidth / 4 - bleendingPixelHorizontal,
            -gridHeight / 2 - bleendingPixelVertical);
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    // switch (renderDirection) {
    //   case TileRenderDirection.bottomRight:
    //     l = bl - (width - gridWidth);
    //     t = bt - (height - gridHeight);
    //     break;
    //   case TileRenderDirection.bottomLeft:
    //     l = bl;
    //     t = bt - (height - gridHeight);
    //     break;
    //   case TileRenderDirection.topRight:
    //     l = bl - (width - gridWidth);
    //     t = bt;
    //     break;
    //   case TileRenderDirection.topLeft:
    //     l = bl;
    //     t = bt;
    //     break;
    //   case TileRenderDirection.bottomCenter:
    //     break;
    // }
    rect = Rect.fromLTWH(
        l - (width - gridWidth) / 2 - bleendingPixelHorizontal / 2 + offsetX,
        t - (height - gridHeight) - bleendingPixelVertical / 2 + offsetY,
        width + bleendingPixelHorizontal,
        height + bleendingPixelVertical);
  }

  @override
  void render(Canvas canvas, [bool showGrids = false]) {
    if (isVoid) return;
    sprite?.renderRect(canvas, rect);
    baseAnimation?.getSprite().renderRect(canvas, rect);
    overlaySprite?.renderRect(canvas, rect);
    overlayAnimation?.getSprite().renderRect(canvas, rect);
    if (showGrids) {
      canvas.drawPath(borderPath, borderPaint);
    }
  }

  void renderCaption(Canvas canvas) {
    if (caption != null) {
      final worldPos =
          tilePosition2TileCenterInWorld(tilePosition.left, tilePosition.top);
      worldPos.y += _kCaptionOffset;
      _captionPaint.render(
        canvas,
        caption!,
        worldPos,
        anchor: Anchor.bottomCenter,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (baseAnimation != null) {
      baseAnimation?.update(dt);
    }
  }
}

int tilePosition2Index(int left, int top, int tileMapWidth) {
  return (left - 1) + (top - 1) * tileMapWidth;
}

mixin TileInfo on Component {
  late final int tileMapWidth;
  late final TileShape tileShape;
  late final double gridWidth, gridHeight;
  late final double srcWidth, srcHeight;
  late final double offsetY;
  late TilePosition _tilePosition;

  TilePosition get tilePosition => _tilePosition;
  set tilePosition(TilePosition position) {
    _tilePosition = position;
    _index =
        tilePosition2Index(_tilePosition.left, _tilePosition.top, tileMapWidth);
    final p = tilePosition2RenderPosition(left, top);
    p.y += offsetY;
    _renderPosition = p;
    _worldPosition = tilePosition2TileCenterInWorld(left, top);
  }

  late Vector2 _renderPosition;
  Vector2 get renderPosition => _renderPosition;

  late Vector2 _worldPosition;
  Vector2 get worldPosition => _worldPosition;

  int get left => _tilePosition.left;
  int get top => _tilePosition.top;

  /// the tile index of the terrain array
  late int _index;
  int get index => _index;

  Vector2 tilePosition2RenderPosition(int left, int top) {
    late final double l, t; //, l, t;
    switch (tileShape) {
      case TileShape.orthogonal:
        l = ((left - 1) * gridWidth);
        t = ((top - 1) * gridHeight);
        break;
      case TileShape.hexagonalVertical:
        l = (left - 1) * gridWidth * (3 / 4);
        t = left.isOdd
            ? (top - 1) * gridHeight
            : (top - 1) * gridHeight + gridHeight / 2;
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    // switch (renderDirection) {
    //   case TileRenderDirection.bottomRight:
    //     l = bl - (srcWidth - gridWidth);
    //     t = bt - (srcHeight - gridHeight);
    //     break;
    //   case TileRenderDirection.bottomLeft:
    //     l = bl;
    //     t = bt - (srcWidth - gridHeight);
    //     break;
    //   case TileRenderDirection.topRight:
    //     l = bl - (srcHeight - gridWidth);
    //     t = bt;
    //     break;
    //   case TileRenderDirection.topLeft:
    //     l = bl;
    //     t = bt;
    //     break;
    //   case TileRenderDirection.bottomCenter:
    //     break;
    // }
    return Vector2(
        l - (srcWidth - gridWidth) / 2, t - (srcHeight - gridHeight));
  }

  Vector2 tilePosition2TileCenterInWorld(int left, int top) {
    late final double rl, rt;
    switch (tileShape) {
      case TileShape.orthogonal:
        rl = ((left - 1) * gridWidth);
        rt = ((top - 1) * gridHeight);
        break;
      case TileShape.hexagonalVertical:
        rl = (left - 1) * gridWidth * (3 / 4) + gridWidth / 2;
        rt = left.isOdd
            ? (top - 1) * gridHeight + gridHeight / 2
            : (top - 1) * gridHeight + gridHeight;
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    return Vector2(rl, rt);
  }

  /// 计算 hexagonal tile 的方向，如果是 backward 则是反方向
  Direction directionTo(TilePosition position, {bool backward = false}) {
    assert(tilePosition != position);
    if (left % 2 != 0) {
      if (position.left == left) {
        if (position.top < top) {
          return backward ? Direction.south : Direction.north;
        } else {
          return backward ? Direction.north : Direction.south;
        }
      } else if (position.left > left) {
        if (position.top == top) {
          if (position.left % 2 != 0) {
            return backward ? Direction.west : Direction.east;
          } else {
            return backward ? Direction.northWest : Direction.southEast;
          }
        } else if (position.top < top) {
          return backward ? Direction.southWest : Direction.northEast;
        } else {
          return backward ? Direction.northWest : Direction.southEast;
        }
      } else {
        if (position.top == top) {
          if (position.left % 2 != 0) {
            return backward ? Direction.east : Direction.west;
          } else {
            return backward ? Direction.northEast : Direction.southWest;
          }
        } else if (position.top < top) {
          return backward ? Direction.southEast : Direction.northWest;
        } else {
          return backward ? Direction.northEast : Direction.southWest;
        }
      }
    } else {
      if (position.left == left) {
        if (position.top < top) {
          return backward ? Direction.south : Direction.north;
        } else {
          return backward ? Direction.north : Direction.south;
        }
      } else if (position.left > left) {
        if (position.top == top) {
          if (position.left.isEven) {
            return backward ? Direction.west : Direction.east;
          } else {
            return backward ? Direction.southWest : Direction.northEast;
          }
        } else if (position.top < top) {
          return backward ? Direction.southWest : Direction.northEast;
        } else {
          return backward ? Direction.northWest : Direction.southEast;
        }
      } else {
        if (position.top == top) {
          if (position.left.isEven) {
            return backward ? Direction.east : Direction.west;
          } else {
            return backward ? Direction.southEast : Direction.northWest;
          }
        } else if (position.top < top) {
          return backward ? Direction.southEast : Direction.northWest;
        } else {
          return backward ? Direction.northEast : Direction.southWest;
        }
      }
    }
  }
}
