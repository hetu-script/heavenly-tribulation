import 'dart:math' as math;

// import 'package:samsara/gestures/gesture_mixin.dart';
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
  late final Sprite backgroundSprite;

  final TileMap map;

  HTStruct worldData;

  TextStyle captionStyle;

  math.Random random = math.Random();

  int cloudCount = 0;

  WorldMapScene({
    required this.worldData,
    required super.controller,
    required super.context,
    required this.captionStyle,
    String? bgm,
    bool showFogOfWar = true,
    bool showNonInteractableHintColor = false,
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

    backgroundSprite = Sprite(await Flame.images.load('universe.png'));

    await map.loadData();
    world.add(map);

    map.moveCameraToTilePosition(map.tileMapWidth ~/ 2, map.tileMapHeight ~/ 2,
        animated: false);

    engine.emit(GameEvents.mapLoaded);

    map.customRender = renderWeather;

    for (var i = 0; i < kMaxCloudsCount ~/ 2; ++i) {
      addCloud();
    }
  }

  void addCloud() {
    final cloud = AnimatedCloud();
    cloud.position = map.getRandomTerrainPosition();
    map.add(cloud);
    ++cloudCount;
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
    backgroundSprite.render(canvas, size: size);

    super.render(canvas);
  }

  void renderWeather(Canvas canvas) {
    // canvas.drawColor(Colors.blue, BlendMode.color);
  }
}
