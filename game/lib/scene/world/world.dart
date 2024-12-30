import 'dart:math' as math;

// import 'package:samsara/gestures/gesture_mixin.dart';
// import 'package:flutter/gestures.dart';
import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
import 'package:hetu_script/values.dart';
import 'package:flame/flame.dart';

import '../../engine.dart';
import 'weather/cloud.dart';
import '../../events.dart';
import '../common.dart';
import '../../ui.dart';
import 'animation/flying_sword.dart';

const kMaxCloudsCount = 16;

class WorldMapScene extends Scene {
  Sprite? backgroundSprite;

  final String? backgroundSpriteId;

  final TileMap map;

  final HTStruct worldData;

  final TextStyle captionStyle;

  final math.Random random = math.Random();

  final bool isMainWorld;

  late FpsComponent fps;

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
          tileMapWidth: worldData['width'],
          tileMapHeight: worldData['height'],
          data: worldData,
          captionStyle: captionStyle,
          tileShape: TileShape.hexagonalVertical,
          gridSize: kGridSize,
          tileSpriteSrcSize: kTileSpriteSrcSize,
          tileOffset: kTileOffset,
          tileFogOffset: kTileFogOffset,
          tileObjectSpriteSrcSize: kTileMapObjectSpriteSrcSize,
          // isCameraFollowHero: false,
          showSelected: true,
          showHover: true,
          showGrids: showGrids,
          // backgroundSpriteId: 'universe.png',
          showFogOfWar: showFogOfWar,
          showNonInteractableHintColor: showNonInteractableHintColor,
          autoUpdateMovingObject: false,
          fogSpriteId: 'shadow.png',
        ),
        super(
          id: worldData['id'],
          bgmFile: bgm,
          bgmVolume: GameConfig.musicVolume,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    camera.zoom = 2.0;

    if (backgroundSpriteId != null) {
      backgroundSprite = Sprite(await Flame.images.load(backgroundSpriteId!));
    }
    world.add(map);

    map.onLoadComplete = () {
      engine.emit(GameEvents.mapLoaded);
    };

    map.onMouseScrollUp = () {
      if (camera.zoom < 4) {
        camera.zoom += 0.2;
      }
    };

    map.onMouseScrollDown = () {
      if (camera.zoom > 0.5) {
        camera.zoom -= 0.2;
      }
    };

    if (isMainWorld) {
      for (var i = 0; i < kMaxCloudsCount ~/ 2; ++i) {
        addCloud();
      }
    }

    fps = FpsComponent();
  }

  void addCloud() {
    final cloud = AnimatedCloud();
    cloud.position = map.getRandomTerrainPosition();
    world.add(cloud);
  }

  /// start & end are flame game canvas world position.
  void useMapSkillFlyingSword(Vector2 start, Vector2 end) {
    final swordAnim = FlyingSword(start: start, end: end);
    map.add(swordAnim);
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);

    // for (final cloud in _clouds) {
    //   cloud.update(dt);
    // }

    if (isMainWorld) {
      final r = math.Random().nextDouble();
      if (r < 0.01) {
        addCloud();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    backgroundSprite?.render(canvas, size: size);

    super.render(canvas);

    if (GameConfig.isDebugMode) {
      drawScreenText(
        canvas,
        'FPS: ${fps.fps.toStringAsFixed(0)}',
        config: ScreenTextConfig(
            textStyle: const TextStyle(fontSize: 20),
            size: GameUI.size,
            anchor: Anchor.topCenter),
      );
    }
  }
}
