import 'package:quiver/core.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../component/game_component.dart';
import '../shared/direction.dart';
import 'entity.dart';

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

enum ZoneCategory {
  empty,
  water,
  continent,
  island,
  lake,
  plain,
  moutain,
  forest,
}

class TileMapTerrain extends GameComponent with TileInfo {
  static const defaultAnimationStepTime = 0.4;
  static const defaultScale = 2.0;

  static final borderPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = Colors.blue;
  final borderPath = Path();
  final shadowPath = Path();
  late Rect rect;

  final Sprite? baseSprite, overlaySprite;
  final SpriteAnimation? baseAnimation, overlayAnimation;
  final double offsetX, offsetY;

  // final TileRenderDirection renderDirection;

  final int zoneIndex;
  final ZoneCategory zoneCategory;

  bool get isWater {
    return zoneCategory == ZoneCategory.lake ||
        zoneCategory == ZoneCategory.water;
  }

  final String? locationId;
  final String? nationId;
  bool isSelectable;
  bool showGrid;

  TileMapEntity? entity;

  TileMapTerrain({
    required TileShape tileShape,
    // this.renderDirection = TileRenderDirection.bottomRight,
    required int left,
    required int top,
    bool isVisible = true,
    this.isSelectable = false,
    this.showGrid = false,
    required int tileMapWidth,
    required double srcWidth,
    required double srcHeight,
    required double gridWidth,
    required double gridHeight,
    required this.zoneIndex,
    required this.nationId,
    this.zoneCategory = ZoneCategory.continent,
    this.locationId,
    this.baseSprite,
    this.baseAnimation,
    this.overlaySprite,
    this.overlayAnimation,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  }) {
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
  void render(Canvas canvas) {
    // if (!isVisible) return;
    baseSprite?.renderRect(canvas, rect);
    baseAnimation?.getSprite().renderRect(canvas, rect);
    overlaySprite?.renderRect(canvas, rect);
    overlayAnimation?.getSprite().renderRect(canvas, rect);
    if (showGrid) {
      canvas.drawPath(borderPath, borderPaint);
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
  late TilePosition _tilePosition;

  TilePosition get tilePosition => _tilePosition;
  set tilePosition(TilePosition position) {
    _tilePosition = position;
    _index =
        tilePosition2Index(_tilePosition.left, _tilePosition.top, tileMapWidth);
    _renderPosition = tilePosition2RenderPosition(left, top);
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

// 计算 hexagonal tile 的方向
  Direction directionTo(TilePosition position) {
    assert(tilePosition != position);
    if (left % 2 != 0) {
      if (position.left == left) {
        if (position.top < top) {
          return Direction.north;
        } else {
          return Direction.south;
        }
      } else if (position.left > left) {
        if (position.top == top) {
          if (position.left % 2 != 0) {
            return Direction.east;
          } else {
            return Direction.southEast;
          }
        } else if (position.top < top) {
          return Direction.northEast;
        } else {
          return Direction.southEast;
        }
      } else {
        if (position.top == top) {
          if (position.left % 2 != 0) {
            return Direction.west;
          } else {
            return Direction.southWest;
          }
        } else if (position.top < top) {
          return Direction.northWest;
        } else {
          return Direction.southWest;
        }
      }
    } else {
      if (position.left == left) {
        if (position.top < top) {
          return Direction.north;
        } else {
          return Direction.south;
        }
      } else if (position.left > left) {
        if (position.top == top) {
          if (position.left.isEven) {
            return Direction.east;
          } else {
            return Direction.northEast;
          }
        } else if (position.top < top) {
          return Direction.northEast;
        } else {
          return Direction.southEast;
        }
      } else {
        if (position.top == top) {
          if (position.left.isEven) {
            return Direction.west;
          } else {
            return Direction.northWest;
          }
        } else if (position.top < top) {
          return Direction.northWest;
        } else {
          return Direction.southWest;
        }
      }
    }
  }
}
