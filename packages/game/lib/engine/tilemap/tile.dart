import 'dart:math';

import 'package:quiver/core.dart';

import 'package:flutter/material.dart';
// import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
// import 'package:flame/extensions.dart';

import '../extensions.dart';
import 'tile_mixin.dart';

class TilePosition {
  final int left, top;

  const TilePosition(this.left, this.top);
  const TilePosition.zero() : this(0, 0);

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
  leftTop,
  rightTop,
  leftBottom,
  rightBottom,
}

class MapTile extends GameComponent with TileInfo {
  static const defaultAnimationStepTime = 0.4;
  static const defaultScale = 2.0;

  static final borderPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = Colors.blue;

  final Sprite? baseSprite, overlaySprite;
  final SpriteAnimation? baseAnimation, overlayAnimation;
  final double offsetX, offsetY;
  final path = Path();
  late Rect rect;

  final TileRenderDirection renderDirection;

  final int zoneIndex;
  bool get isVoid => baseSprite == null;
  final bool isWater;
  final String? locationId;

  MapTile({
    required TileShape shape,
    this.renderDirection = TileRenderDirection.rightBottom,
    required int left,
    required int top,
    required int tileMapWidth,
    required double srcWidth,
    required double srcHeight,
    required double gridWidth,
    required double gridHeight,
    required bool isVisible,
    required this.zoneIndex,
    this.isWater = false,
    this.locationId,
    this.baseSprite,
    this.baseAnimation,
    this.overlaySprite,
    this.overlayAnimation,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  }) {
    this.tileMapWidth = tileMapWidth;
    this.shape = shape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = width = srcWidth;
    this.srcHeight = height = srcHeight;
    tilePosition = TilePosition(left, top);
    generateRect();
    this.isVisible = isVisible;
  }

  void generateRect() {
    double sizeMax = max(width, height);
    double bleendingPixel = sizeMax * 0.04;
    if (bleendingPixel > 2) {
      bleendingPixel = 2;
    }

    late final double l, t, bl, bt;
    switch (shape) {
      case TileShape.orthogonal:
        bl = ((left - 1) * gridWidth);
        bt = ((top - 1) * gridHeight);
        final border = Rect.fromLTWH(bl, bt, gridWidth, gridHeight);
        path.addRect(border);
        break;
      case TileShape.hexagonalVertical:
        bl = (left - 1) * gridWidth * (3 / 4);
        bt = left.isOdd
            ? (top - 1) * gridHeight
            : (top - 1) * gridHeight + gridHeight / 2;
        path.moveTo(bl, bt + gridHeight / 2);
        path.relativeLineTo(gridWidth / 4, -gridHeight / 2);
        path.relativeLineTo(gridWidth / 2, 0);
        path.relativeLineTo(gridWidth / 4, gridHeight / 2);
        path.relativeLineTo(-gridWidth / 4, gridHeight / 2);
        path.relativeLineTo(-gridWidth / 2, 0);
        path.relativeLineTo(-gridWidth / 4, -gridHeight / 2);
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    switch (renderDirection) {
      case TileRenderDirection.rightBottom:
        l = bl - (width - gridWidth);
        t = bt - (height - gridHeight);
        break;
      case TileRenderDirection.leftBottom:
        l = bl;
        t = bt - (height - gridHeight);
        break;
      case TileRenderDirection.rightTop:
        l = bl - (width - gridWidth);
        t = bt;
        break;
      case TileRenderDirection.leftTop:
        l = bl;
        t = bt;
        break;
    }
    rect = Rect.fromLTWH(
        l - bleendingPixel / 2 + offsetX,
        t - bleendingPixel / 2 + offsetY,
        width + bleendingPixel,
        height + bleendingPixel);
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) {
      return;
    }
    baseSprite?.renderRect(canvas, rect);
    baseAnimation?.getSprite().renderRect(canvas, rect);
    overlaySprite?.renderRect(canvas, rect);
    overlayAnimation?.getSprite().renderRect(canvas, rect);

    // final spriteBorderPaint = Paint()
    //   ..strokeWidth = 0.1
    //   ..style = PaintingStyle.stroke
    //   ..color = Colors.red;
    // switch (tileType) {
    //   case TileType.orthogonal:
    // canvas.drawRect(rect, borderPaint);
    canvas.drawPath(path, borderPaint);
    //     break;
    //   case TileType.isometric:
    //     throw 'Isometric map tile is not supported yet!';
    //   case TileType.hexagonalVertical:
    //     break;
    //   case TileType.hexagonalHorizontal:
    //     break;
    // }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (baseAnimation != null) {
      baseAnimation?.update(dt);
    }
  }
}
