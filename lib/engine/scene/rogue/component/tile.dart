import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';

import '../../../extensions.dart';
// import '../../../../util/math.dart';

class Tile extends GameComponent {
  static const defaultSrcTileWidth = 32.0;
  static const defaultSrcTileHeight = 32.0;
  static const defaultAnimationStepTime = 0.4;
  static const defaultScale = 2.0;

  Sprite? sprite;
  SpriteAnimation? animation;
  double offsetX, offsetY;
  Path path = Path();
  late Rect rect;
  int left,
      top; // the tile position (compare to screen position or world position)

  void generateRectWithBleedingPixel() {
    isVisible = false;
    double sizeMax = max(width, height);
    double bleendingPixel = sizeMax * 0.04;
    if (bleendingPixel > 3) {
      bleendingPixel = 3;
    }
    rect = Rect.fromLTWH(
      (left * width) - (left % 2 == 0 ? (bleendingPixel / 2) : 0) + offsetX,
      (top * height) - (top % 2 == 0 ? (bleendingPixel / 2) : 0) + offsetY,
      width + (left % 2 == 0 ? bleendingPixel : 0),
      height + (top % 2 == 0 ? bleendingPixel : 0),
    );
  }

  Tile({
    required this.left,
    required this.top,
    required double width,
    required double height,
    this.sprite,
    this.animation,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  }) {
    this.width = width;
    this.height = height;
    generateRectWithBleedingPixel();
    path.addRect(rect);
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
    // if (isVisited) {
    //   Tile.visitedSprite?.renderRect(canvas, rect);
    //   canvas.drawPath(
    //       Path()
    //         ..addRect(rect)
    //         ..fillType = PathFillType.evenOdd,
    //       Paint()
    //         ..color = Colors.black.withAlpha(128)
    //         ..maskFilter = MaskFilter.blur(BlurStyle.normal, radiusToSigma(3)));
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

class Terrain extends Tile {
  bool get isVoid => sprite == null;
  bool isRoom;
  bool isVisited;
  bool isCleared = false;

  Terrain({
    required int left,
    required int top,
    required double width,
    required double height,
    this.isRoom = false,
    this.isVisited = false,
    Sprite? sprite,
    SpriteAnimation? animation,
    double offsetX = 0.0,
    double offsetY = 0.0,
  }) : super(
          left: left,
          top: top,
          width: width,
          height: height,
          sprite: sprite,
          animation: animation,
          offsetX: offsetX,
          offsetY: offsetY,
        );
}

class Entity extends Tile {
  final String id;

  Entity({
    required this.id,
    required int left,
    required int top,
    double width = Tile.defaultSrcTileWidth,
    double height = Tile.defaultSrcTileHeight,
    Sprite? sprite,
    SpriteAnimation? animation,
    double offsetX = 0.0,
    double offsetY = 0.0,
  }) : super(
          left: left,
          top: top,
          width: width,
          height: height,
          sprite: sprite,
          animation: animation,
          offsetX: offsetX,
          offsetY: offsetY,
        );

  static Future<Entity> fromJson(Map<String, dynamic> jsonData) async {
    String id = jsonData['id'];
    int left = jsonData['x'];
    int top = jsonData['y'];
    double width = jsonData['width'] ?? Tile.defaultSrcTileWidth;
    double height = jsonData['height'] ?? Tile.defaultSrcTileHeight;
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
        srcSize: Vector2(width, height),
      );
    }
    if (animationPath != null) {
      final sheet = SpriteSheet(
          image: await Flame.images.load(animationPath),
          srcSize: Vector2(
            width,
            height,
          ));
      animation = sheet.createAnimation(
          row: 0,
          stepTime: Tile.defaultAnimationStepTime,
          from: 0,
          to: animationFrameCount);
    }

    return Entity(
      id: id,
      left: left,
      top: top,
      width: width,
      height: height,
      sprite: sprite,
      animation: animation,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }
}
