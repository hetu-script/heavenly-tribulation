import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import '../component/game_component.dart';
import 'tile.dart';

class TileMapTerrain extends GameComponent with TileInfo {
  static const defaultAnimationStepTime = 0.2;

  static final borderPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = Colors.blue;

  /// internal data of this tile, possible json or other user-defined data form.
  final dynamic data;

  final borderPath = Path();
  final shadowPath = Path();
  late Rect rect;

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
  SpriteAnimation? animation, overlayAnimation;

  // 随机数，用来让多个 tile 的贴图动画错开播放
  late final double _overlayAnimationOffset;
  double _overlayAnimationOffsetValue = 0;

  Future<Sprite?> _loadSprite(
      dynamic data, SpriteSheet terrainSpriteSheet) async {
    Sprite? sprite;
    if (data != null) {
      final String? spritePath = data['sprite'];
      final int? spriteIndex = data['spriteIndex'];
      if (spritePath != null) {
        sprite = await Sprite.load(
          spritePath,
          srcSize: Vector2(srcWidth, srcHeight),
        );
      } else if (spriteIndex != null) {
        sprite = terrainSpriteSheet.getSpriteById(spriteIndex - 1);
      }
    }
    return sprite;
  }

  Future<SpriteAnimation?> _loadAnimation(
      dynamic data, SpriteSheet terrainSpriteSheet,
      {bool loop = true}) async {
    SpriteAnimation? animation;
    if (data != null) {
      final String? animationPath = data['animation'];
      final int? animationFrameCount = data['animationFrameCount'];
      final int? animationRow = data['row'];
      final int? animationStart = data['start'];
      final int? animationEnd = data['end'];
      if (animationPath != null) {
        final sheet = SpriteSheet(
            image: await Flame.images.load(animationPath),
            srcSize: Vector2(
              srcWidth,
              srcHeight,
            ));
        animation = sheet.createAnimation(
            row: 0,
            stepTime: defaultAnimationStepTime,
            loop: loop,
            from: 0,
            to: animationFrameCount ?? sheet.columns);
      } else if (animationRow != null) {
        animation = terrainSpriteSheet.createAnimation(
          row: animationRow,
          stepTime: defaultAnimationStepTime,
          loop: loop,
          from: animationStart ?? 0,
          to: animationEnd ?? terrainSpriteSheet.columns,
        );
      }
    }
    return animation;
  }

  void loadSprite(dynamic data, SpriteSheet terrainSpriteSheet) async {
    sprite = await _loadSprite(data, terrainSpriteSheet);
    animation = await _loadAnimation(data, terrainSpriteSheet);
  }

  void loadOverlaySprite(dynamic data, SpriteSheet terrainSpriteSheet) async {
    overlaySprite = await _loadSprite(data, terrainSpriteSheet);
    overlayAnimation =
        await _loadAnimation(data, terrainSpriteSheet, loop: false);
  }

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
    this.animation,
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
    srcOffsetY = 0;
    tilePosition = TilePosition(left, top);
    generateRect();
    this.isVisible = isVisible;

    _overlayAnimationOffset = math.Random().nextDouble() * 3;
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
    animation?.getSprite().renderRect(canvas, rect);
    overlaySprite?.renderRect(canvas, rect);
    overlayAnimation?.getSprite().renderRect(canvas, rect);
    if (showGrids) {
      canvas.drawPath(borderPath, borderPaint);
    }
  }

  void renderCaption(Canvas canvas, {offset = 14.0}) {
    if (caption != null) {
      final worldPos =
          tilePosition2TileCenterInWorld(tilePosition.left, tilePosition.top);
      worldPos.y += offset;
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
    animation?.update(dt);
    if (overlayAnimation != null) {
      overlayAnimation?.update(dt);
      if (overlayAnimation!.done()) {
        _overlayAnimationOffsetValue += dt;
        if (_overlayAnimationOffsetValue >= _overlayAnimationOffset) {
          _overlayAnimationOffsetValue = 0;
          overlayAnimation!.reset();
        }
      }
    }
  }
}
