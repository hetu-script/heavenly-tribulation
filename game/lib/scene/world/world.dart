import 'dart:math' as math;

// import 'package:samsara/gestures/gesture_mixin.dart';
import 'package:flutter/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
import 'package:hetu_script/values.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import '../../config.dart';
import 'weather/cloud.dart';
import '../../events.dart';
import 'common.dart';

const kMaxCloudsCount = 16;

class WorldMapScene extends Scene {
  Sprite? backgroundSprite;

  final String? backgroundSpriteId;

  final TileMap map;

  final HTStruct worldData;

  final TextStyle captionStyle;

  final math.Random random = math.Random();

  final bool isMainWorld;

  WorldMapScene({
    required this.worldData,
    required super.controller,
    required super.context,
    required this.captionStyle,
    required this.isMainWorld,
    this.backgroundSpriteId,
    String? bgm,
    bool showFogOfWar = true,
    bool showNonInteractableHintColor = false,
    bool showGrids = false,
  })  : map = TileMap(
          id: worldData['id'],
          data: worldData,
          captionStyle: captionStyle,
          tileShape: TileShape.hexagonalVertical,
          gridWidth: 32.0,
          gridHeight: 28.0,
          tileSpriteSrcWidth: 32.0,
          tileSpriteSrcHeight: 64.0,
          tileOffsetX: 0.0,
          tileOffsetY: 16.0,
          tileObjectSpriteSrcWidth: kTileMapObjectSpriteSrcSize.x,
          tileObjectSpriteSrcHeight: kTileMapObjectSpriteSrcSize.y,
          scaleFactor: 2.0,
          showSelected: true,
          showHover: true,
          showGrids: showGrids,
          // backgroundSpriteId: 'universe.png',
          showFogOfWar: showFogOfWar,
          showNonInteractableHintColor: showNonInteractableHintColor,
          autoUpdateMovingObject: false,
        ),
        super(
          id: worldData['id'],
          bgmFile: bgm,
          bgmVolume: GameConfig.musicVolume,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    if (backgroundSpriteId != null) {
      backgroundSprite = Sprite(await Flame.images.load(backgroundSpriteId!));
    }

    await map.loadData();
    world.add(map);

    map.onDragUpdate = (int buttons, Vector2 dragPosition, Vector2 dragOffset) {
      if (buttons == kSecondaryButton) {
        camera.moveBy(-dragOffset / camera.viewfinder.zoom);
      }
    };

    map.onMouseHover = (Vector2 position) {
      final tilePosition = map.worldPosition2Tile(position);
      map.hoverTerrain = map.getTerrainByPosition(tilePosition);
    };

    map.moveCameraToTilePosition(map.tileMapWidth ~/ 2, map.tileMapHeight ~/ 2,
        animated: false);

    map.customRender = renderWeather;

    for (var i = 0; i < kMaxCloudsCount ~/ 2; ++i) {
      addCloud();
    }

    engine.emit(GameEvents.mapLoaded);
  }

  void addCloud() {
    final cloud = AnimatedCloud();
    cloud.position = map.getRandomTerrainPosition();
    map.add(cloud);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // for (final cloud in _clouds) {
    //   cloud.update(dt);
    // }
    final r = math.Random().nextDouble();
    if (r < 0.01) {
      addCloud();
    }
  }

  @override
  void render(Canvas canvas) {
    backgroundSprite?.render(canvas, size: size);

    super.render(canvas);
  }

  void renderWeather(Canvas canvas) {
    // canvas.drawColor(Colors.blue, BlendMode.color);
  }
}
