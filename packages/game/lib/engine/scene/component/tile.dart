import 'dart:math';

import 'package:quiver/core.dart';

import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';

import '../../extensions.dart';

class TilePosition {
  final int left, top;

  const TilePosition(this.left, this.top);

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

class MapTile extends GameComponent {
  static const defaultAnimationStepTime = 0.4;
  static const defaultScale = 2.0;

  static final borderPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = Colors.blue;

  final Sprite? sprite;
  final SpriteAnimation? animation;
  final double offsetX, offsetY;
  final path = Path();
  late Rect rect;
  final int left,
      top; // the tile position (compare to screen position or world position)
  final double gridWidth, gridHeight;

  final TileShape shape;
  final TileRenderDirection renderDirection;

  final int zoneIndex;

  MapTile({
    required this.shape,
    this.renderDirection = TileRenderDirection.rightBottom,
    required this.left,
    required this.top,
    required double srcWidth,
    required double srcHeight,
    required this.gridWidth,
    required this.gridHeight,
    required bool isVisible,
    this.zoneIndex = -1,
    this.sprite,
    this.animation,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  }) {
    width = srcWidth;
    height = srcHeight;
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
    super.render(canvas);
    sprite?.renderRect(canvas, rect);
    if (animation != null) {
      animation?.getSprite().renderRect(canvas, rect);
    }

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
    if (animation != null) {
      animation?.update(dt);
    }
  }
}

class Terrain extends MapTile {
  bool get isVoid => sprite == null;
  bool isRoom;
  bool isVisited;
  bool isCleared = false;

  Terrain({
    required TileShape shape,
    TileRenderDirection renderDirection = TileRenderDirection.rightBottom,
    required int left,
    required int top,
    required double srcWidth,
    required double srcHeight,
    required double gridWidth,
    required double gridHeight,
    required bool isVisible,
    required int zoneIndex,
    this.isRoom = false,
    this.isVisited = false,
    Sprite? sprite,
    SpriteAnimation? animation,
    double offsetX = 0.0,
    double offsetY = 0.0,
  }) : super(
          shape: shape,
          renderDirection: renderDirection,
          left: left,
          top: top,
          srcWidth: srcWidth,
          srcHeight: srcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          isVisible: isVisible,
          zoneIndex: zoneIndex,
          sprite: sprite,
          animation: animation,
          offsetX: offsetX,
          offsetY: offsetY,
        );
}

class Entity extends MapTile {
  final String id;

  Entity({
    required TileShape shape,
    TileRenderDirection renderDirection = TileRenderDirection.rightBottom,
    required this.id,
    required int left,
    required int top,
    required double srcWidth,
    required double srcHeight,
    required double gridWidth,
    required double gridHeight,
    required bool isVisible,
    Sprite? sprite,
    SpriteAnimation? animation,
    double offsetX = 0.0,
    double offsetY = 0.0,
  }) : super(
          shape: shape,
          renderDirection: renderDirection,
          left: left,
          top: top,
          srcWidth: srcWidth,
          srcHeight: srcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          isVisible: isVisible,
          sprite: sprite,
          animation: animation,
          offsetX: offsetX,
          offsetY: offsetY,
        );

  static Future<Entity> fromJson(
      {required TileShape type,
      required double gridWidth,
      required double gridHeight,
      required double spriteSrcWidth,
      required double spriteSrcHeight,
      required bool isVisible,
      required Map<String, dynamic> jsonData}) async {
    String id = jsonData['id'];
    int left = jsonData['x'];
    int top = jsonData['y'];
    double srcWidth = jsonData['srcWidth'];
    double srcHeight = jsonData['srcHeight'];
    double offsetX = jsonData['offsetX'] ?? 0.0;
    double offsetY = jsonData['offsetY'] ?? 0.0;
    String? spritePath = jsonData['sprite'];
    String? animationPath = jsonData['animation'];
    int animationFrameCount = jsonData['animationFrameCount'] ?? 1;
    Sprite? sprite;
    SpriteAnimation? animation;
    if (spritePath != null) {
      sprite = await Sprite.load(
        spritePath,
        srcSize: Vector2(srcWidth, srcHeight),
      );
    }
    if (animationPath != null) {
      final sheet = SpriteSheet(
          image: await Flame.images.load(animationPath),
          srcSize: Vector2(
            srcWidth,
            srcHeight,
          ));
      animation = sheet.createAnimation(
          row: 0,
          stepTime: MapTile.defaultAnimationStepTime,
          from: 0,
          to: animationFrameCount);
    }

    return Entity(
      shape: type,
      id: id,
      left: left,
      top: top,
      srcWidth: srcWidth,
      srcHeight: srcHeight,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      isVisible: isVisible,
      sprite: sprite,
      animation: animation,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }
}
