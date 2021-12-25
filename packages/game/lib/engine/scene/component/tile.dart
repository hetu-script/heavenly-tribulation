import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';

import '../../extensions.dart';

class TilePosition {
  final int left, top;

  TilePosition(this.left, this.top);

  @override
  String toString() => '[$left,$top]';
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

  final Sprite? sprite;
  final SpriteAnimation? animation;
  final double offsetX, offsetY;
  final path = Path();
  late Rect rect, border;
  final int left,
      top; // the tile position (compare to screen position or world position)
  final double gridWidth, gridHeight;

  final TileShape shape;
  final TileRenderDirection renderDirection;

  void generateRect() {
    double sizeMax = max(width, height);
    double bleendingPixel = sizeMax * 0.04;
    if (bleendingPixel > 3) {
      bleendingPixel = 3;
    }

    late final double l, t;
    switch (shape) {
      case TileShape.orthogonal:
        l = ((left - 1) * gridWidth);
        t = ((top - 1) * gridHeight);
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalVertical:
        l = (left - 1) * gridWidth * (3 / 4);
        t = left.isOdd
            ? (top - 1) * gridHeight
            : (top - 1) * gridHeight + gridHeight / 2;
        break;
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    rect = Rect.fromLTWH(
        l - (left % 2 == 0 ? (bleendingPixel / 2) : 0) + offsetX,
        t - (top % 2 == 0 ? (bleendingPixel / 2) : 0) + offsetY,
        width + (left % 2 == 0 ? bleendingPixel : 0),
        height + (top % 2 == 0 ? bleendingPixel : 0));

    switch (renderDirection) {
      case TileRenderDirection.rightBottom:
        border = Rect.fromLTWH(l - (width - gridWidth),
            t - (height - gridHeight), gridWidth, gridHeight);
        break;
      case TileRenderDirection.leftBottom:
        border =
            Rect.fromLTWH(l, t - (height - gridHeight), gridWidth, gridHeight);
        break;
      case TileRenderDirection.rightTop:
        border =
            Rect.fromLTWH(l - (width - gridWidth), t, gridWidth, gridHeight);
        break;
      case TileRenderDirection.leftTop:
        border = Rect.fromLTWH(l, t, gridWidth, gridHeight);
        break;
    }
  }

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
    this.sprite,
    this.animation,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  }) {
    width = srcWidth;
    height = srcHeight;
    generateRect();
    path.addRect(rect);
    this.isVisible = isVisible;
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

    // final tileBorderPaint = Paint()
    //   ..strokeWidth = 0.1
    //   ..style = PaintingStyle.stroke
    //   ..color = Colors.blue;
    // switch (tileType) {
    //   case TileType.orthogonal:
    // canvas.drawRect(rect, spriteBorderPaint);
    // canvas.drawRect(border, tileBorderPaint);
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
