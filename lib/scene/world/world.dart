import 'dart:async';

import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
import 'package:hetu_script/values.dart';
import 'package:flame/flame.dart';
import 'package:provider/provider.dart';
import 'package:samsara/effect/camera_shake.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/widgets/ui/menu_builder.dart';
import 'package:samsara/hover_info.dart';

import '../../extensions.dart';
import '../../global.dart';
import 'particles/cloud.dart';
import 'particles/rubble.dart';
import '../common.dart';
import '../../ui.dart';
import '../../data/game.dart';
import '../../state/states.dart';
import '../../widgets/ui_overlay.dart';
import '../../widgets/dialog/input_string.dart';
import '../../widgets/information.dart';
import 'widgets/entity_list.dart';
import 'widgets/tile_detail.dart';
import 'widgets/toolbox.dart';
import '../../logic/logic.dart';
import 'animation/banner.dart';
import '../../data/common.dart';
import 'widgets/location_panel.dart';
import 'widgets/drop_menu.dart';
import '../cursor_state.dart';

final kGridSize = Vector2(32.0, 28.0);
final kTileSpriteSrcSize = Vector2(32.0, 64.0);
final kTileOffset = Vector2(0.0, -21.0);
final kTileFogOffset = Vector2(-6.0, 0.0);
final kCharacterAnimationSize = Vector2(32.0, 48.0);

const kTerrainKindVoid = 'void';
const kTerrainKindPlain = 'plain';
const kTerrainKindMountain = 'mountain';
const kTerrainKindForest = 'forest';
const kTerrainKindSnowPlain = 'snow_plain';
const kTerrainKindSnowMountain = 'snow_mountain';
const kTerrainKindSnowForest = 'snow_forest';
const kTerrainKindShore = 'shore';
const kTerrainKindShelf = 'shelf';
const kTerrainKindLake = 'lake';
const kTerrainKindSea = 'sea';
const kTerrainKindRiver = 'river';
const kTerrainKindRoad = 'road';
const kTerrainKindCity = 'city';

enum WorldEditorDropMenuItems {
  addWorld,
  switchWorld,
  deleteWorld,
  expandWorld,
  save,
  saveAs,
  saveMapAs,
  viewNone,
  viewContinents,
  viewCities,
  viewSects,
  generateZone,
  reloadGameData,
  characterCalculateStats,
  console,
  exit,
}

enum TerrainPopUpMenuItems {
  checkInformation,
  setTerritory,
  clearTerritory,
  bindLocation,
  clearLocation,
  bindObject,
  clearObject,
  clearDecoration,
  empty,
  plain,
  forest,
  mountain,
  shore,
  shelf,
  lake,
  sea,
  river,
  road,
  city,
  clearTerrainSprite,
  clearTerrainAnimation,
  clearTerrainOverlaySprite,
  clearTerrainOverlayAnimation,
}

const kExcludeTerrainKindsOnLighting = ['void', 'mountain'];
const kMaxCloudsCount = 16;

const _kInitialCharacterSelectionCount = 5;

class WorldMapScene extends Scene with HasCursorState {
  WorldMapScene({
    required super.context,
    required this.worldData,
    required this.isEditorMode,
    this.backgroundSpriteId,
    super.bgmFile,
  })  : assert(GameData.spriteSheets
            .containsKey('tilemap/fantasyhextiles_v3_borderless.png')),
        map = TileMap(
          logger: engine,
          terrainSpriteSheet: GameData
              .spriteSheets['tilemap/fantasyhextiles_v3_borderless.png']!,
          id: worldData['id'],
          tileMapWidth: worldData['width'],
          tileMapHeight: worldData['height'],
          data: worldData,
          captionStyle: TextStyles.labelLarge,
          tileShape: TileShape.hexagonalVertical,
          gridSize: kGridSize,
          tileSpriteSrcSize: kTileSpriteSrcSize,
          tileOffset: kTileOffset,
          tileFogOffset: kTileFogOffset,
          showSelected: true,
          showHover: true,
          showFogOfWar: false, // !isEditorMode,
          autoUpdateComponent: false,
          fogSpriteId: 'shadow.png',
          // isCameraFollowHero: false,
          // backgroundSpriteId: 'universe.png',
          isEditorMode: isEditorMode,
        ),
        super(
          id: worldData['id'],
          bgmVolume: engine.config.musicVolume,
        );

  final _focusNode = FocusNode();

  Sprite? backgroundSprite;

  final String? backgroundSpriteId;

  final TileMap map;

  final dynamic worldData;

  final bool isEditorMode;

  bool get isMainWorld => worldData['isMain'] ?? false;

  late final FpsComponent fps;

  late final Timer mainTimer;

  final menuController = fluent.FlyoutController();

  dynamic territoryMode;

  List charactersOnWorldMap = [];

  // 跟随目标相关
  String? _followingTargetId;

  bool _playerFreezed = false;
  set playerFreezed(bool value) {
    _playerFreezed = map.autoUpdateComponent = value;
  }

  // 当场景 onLoad 和地图 onAfterLoaded 都执行完毕后，初始化完成
  // 地图场景的初始化在游戏运行时只会执行一次，已经执行初始化后，onMount中会有一些差别处理
  bool _isInitializing = true;

  void _setSelectedTerrain(TileMapTerrain? terrain) {
    if (terrain == null) {
      context.read<WorldMapState>().clearTerrain();
      return;
    }

    dynamic selectedZone;
    dynamic selectedNation;
    dynamic selectedLocation;

    final zoneId = terrain.zoneId;
    if (zoneId != null) {
      selectedZone =
          engine.hetu.invoke('getZoneById', positionalArgs: [zoneId]);
    } else {
      selectedZone = null;
    }

    final nationId = terrain.nationId;
    if (nationId != null) {
      selectedNation =
          engine.hetu.invoke('getSectById', positionalArgs: [nationId]);
    } else {
      selectedNation = null;
    }

    final String? locationId = terrain.locationId;
    if (locationId != null) {
      selectedLocation = GameData.getLocation(locationId);
    } else {
      selectedLocation = null;
    }

    context.read<WorldMapState>().updateSelectedTerrain(
          currentZoneData: selectedZone,
          currentNationData: selectedNation,
          currentLocationData: selectedLocation,
          currentTerrainObject: terrain,
        );
  }

  Future<void> _updateHeroAtTerrain({
    TileMapTerrain? tile,
    // bool moveCameraToHero = true,
    bool animated = false,
    bool notify = true,
  }) async {
    if (map.hero == null) return;

    final terrain = tile ?? map.getHeroAtTerrain();
    if (terrain == null) return;

    dynamic heroAtZone;
    dynamic heroAtNation;

    final zoneId = terrain.zoneId;
    if (zoneId != null) {
      heroAtZone = engine.hetu.invoke('getZoneById', positionalArgs: [zoneId]);
    } else {
      heroAtZone = null;
    }
    final nationId = terrain.nationId;
    if (nationId != null) {
      heroAtNation =
          engine.hetu.invoke('getSectById', positionalArgs: [nationId]);
    } else {
      heroAtNation = null;
    }

    gameState.updateTerrain(
      currentZoneData: heroAtZone,
      currentNationData: heroAtNation,
      currentTerrainData: terrain,
      notify: notify,
    );

    // if (moveCameraToHero) {
    //   await map.moveCameraToHero(animated: animated);
    // }

    await _updateNpcsAtHeroPosition();
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);

    if (map.isStandby) {
      mainTimer.update(dt);
    }

    if (!isEditorMode && isMainWorld) {
      if (map.isLoaded) {
        final r = ParticleCloud.random.nextDouble();
        if (r < 0.01) {
          _addCloud();
        }
      }
    }
  }

  // @override
  // void render(Canvas canvas) {
  //   backgroundSprite?.render(canvas, size: size);

  //   super.render(canvas);

  //   // if (engine.config.debugMode || engine.config.showFps) {
  //   //   drawScreenText(
  //   //     canvas,
  //   //     'FPS: ${fps.fps.toStringAsFixed(0)}',
  //   //     config: ScreenTextConfig(
  //   //       textStyle: const TextStyle(fontSize: 20),
  //   //       size: GameUI.size,
  //   //       anchor: Anchor.topCenter,
  //   //       padding: const EdgeInsets.only(top: 40),
  //   //     ),
  //   //   );
  //   // }
  // }

  void _loadBindings() {
    engine.hetu.interpreter.bindExternalFunction('World::updateTerrainSprite', (
        {positionalArgs, namedArgs}) async {
      if (!map.isLoaded) return;
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      await tile?.tryLoadSprite();
    }, override: true);

    engine.hetu.interpreter
        .bindExternalFunction('World::updateTerrainOverlaySprite', (
            {positionalArgs, namedArgs}) async {
      if (!map.isLoaded) return;
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      await tile?.tryLoadSprite(isOverlay: true);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::updateTerrainData', (
        {positionalArgs, namedArgs}) async {
      if (!map.isLoaded) return;
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      await tile?.updateData(
        updateSprite: namedArgs['updateSprite'] ?? false,
        updateOverlaySprite: namedArgs['updateOverlaySprite'] ?? false,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::setTerrainCaption', (
        {positionalArgs, namedArgs}) {
      _setWorldMapCaption(
        positionalArgs[0],
        positionalArgs[1],
        positionalArgs[2],
        HexColor.fromString(positionalArgs[3] ?? '#ffffff'),
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::darkenAllTiles', (
        {positionalArgs, namedArgs}) {
      map.darkenAllTiles();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::lightUpAllTiles', (
        {positionalArgs, namedArgs}) {
      map.lightUpAllTiles();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::setPlayerFreeze', (
        {positionalArgs, namedArgs}) {
      playerFreezed = positionalArgs.first;
    }, override: true);

    engine.hetu.interpreter
        .bindExternalFunction('World::setCharacterToWorldPosition', (
            {positionalArgs, namedArgs}) async {
      return _characterSetToWorldPosition(
        positionalArgs[0],
        positionalArgs[1],
        positionalArgs[2],
        direction: namedArgs['direction'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::removeCharacter', (
        {positionalArgs, namedArgs}) {
      map.components.remove(positionalArgs.first)?.removeFromParent();
    });

    engine.hetu.interpreter.bindExternalFunction('World::characterWalkTo', (
        {positionalArgs, namedArgs}) async {
      final charObj = map.components[positionalArgs[0]];
      if (charObj == null) {
        engine.warning('大地图对象 id [${positionalArgs[0]}] 不存在');
        return null;
      }
      charObj.isWalkCanceled = false;
      final completer = Completer();
      final int toX = positionalArgs[1];
      final int toY = positionalArgs[2];
      final String? endDirString = namedArgs['endDirection'];
      OrthogonalDirection? finishDirection;
      if (endDirString != null) {
        finishDirection = OrthogonalDirection.values
            .singleWhere((element) => element.name == endDirString);
      }
      final HTFunction? onStepCallback = namedArgs['onStepCallback'];

      final route = await GameLogic.calculateRoute(
        fromX: charObj.left,
        fromY: charObj.top,
        toX: toX,
        toY: toY,
        isHero: false,
      );
      if (route != null) {
        assert(route.length > 1);
        charObj.walkToTilePositionByRoute(
          List<int>.from(route),
          finishDirection: finishDirection,
          onStepCallback: (terrain, next, isFinished) {
            onStepCallback?.call(positionalArgs: [terrain.data, next?.data]);
            completer.complete();
            map.updateTileInfo(charObj);
            return false;
          },
        );
      } else {
        engine.error(
            '无法将对象 ${charObj.id} 从大地图位置 [${charObj.tilePosition}] 移动到 [$toX, $toY]}');
        completer.complete();
      }
      return completer.future;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::setObjectTo', (
        {positionalArgs, namedArgs}) {
      final object = map.components[positionalArgs[0]];
      if (object == null) {
        engine.warning(
            'object with id [${positionalArgs[0]}] not found in map component list.');
        return;
      }
      object.tilePosition = TilePosition(positionalArgs[1], positionalArgs[2]);
      map.updateTileInfo(object);
    });

    engine.hetu.interpreter.bindExternalFunction(
        'World::updateNpcsAtWorldMapPosition',
        ({positionalArgs, namedArgs}) => _updateNpcsAtHeroPosition(),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'World::updateWorldMapLocations',
        ({positionalArgs, namedArgs}) => _loadWorldMapCaptions(),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('World::addHintText', (
        {positionalArgs, namedArgs}) {
      final hexString = positionalArgs[3];
      Color? color;
      if (hexString != null) {
        color = HexColor.fromString(hexString);
      }
      addHintTextOnTile(
        positionalArgs[0],
        positionalArgs[1],
        positionalArgs[2],
        color: color,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::promptTextBanner',
        ({positionalArgs, namedArgs}) => promptTextBanner(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('World::lightUpAroundTile', (
        {positionalArgs, namedArgs}) {
      map.lightUpAroundTile(
        TilePosition(positionalArgs[0], positionalArgs[1]),
        size: positionalArgs[2],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::enterLocation', (
        {positionalArgs, namedArgs}) {
      GameLogic.tryEnterLocation(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::showFog', (
        {positionalArgs, namedArgs}) {
      map.showFogOfWar = positionalArgs.first;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'World::moveCameraToTilePosition',
        ({positionalArgs, namedArgs}) => map.moveCameraToTilePosition(
              positionalArgs[0],
              positionalArgs[1],
              animated: namedArgs['animated'],
            ),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('World::shakeCamera', (
        {positionalArgs, namedArgs}) {
      final Completer completer = Completer();
      add(
        CameraShakeEffect(
          intensity: namedArgs['intensity'],
          shift: namedArgs['shift'],
          frequency: namedArgs['frequency'],
          controller: EffectController(duration: namedArgs['duration']),
          onComplete: () {
            completer.complete();
          },
        ),
      );
      return completer.future;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::addFallingRubbles', (
        {positionalArgs, namedArgs}) {
      final int amount = namedArgs['amount'];
      for (var i = 0; i < amount; ++i) {
        camera.viewport.add(ParticleRubble());
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'World::setMapComponentVisible', ({positionalArgs, namedArgs}) {
      map.setMapComponentVisible(positionalArgs[0], positionalArgs[1]);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::clearMapComponents', (
        {positionalArgs, namedArgs}) {
      map.clearMapComponents();
    }, override: true);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    camera.zoom = 2.0;

    if (backgroundSpriteId != null) {
      backgroundSprite = Sprite(await Flame.images.load(backgroundSpriteId!));
    }

    GameData.loadZoneColors(map);
    map.colorMode = kColorModeNation;

    map.onAfterLoaded =
        isEditorMode ? _onAfterLoadedInEditorMode : _onAfterLoadedInGameMode;

    map.onMouseEnterScreenEdge = _onMouseEnterScreenEdge;

    map.onMouseEnterTile = _onMouseEnterTile;

    // map.onMouseScrollUp = () {
    //   if (camera.zoom < 4) {
    //     camera.zoom += 0.2;
    //   }
    // };

    // map.onMouseScrollDown = () {
    //   if (camera.zoom > 2) {
    //     camera.zoom -= 0.2;
    //   }
    // };

    map.onTapDown =
        isEditorMode ? _onTapDownInEditorMode : _onTapDownInGameMode;
    map.onTapUp = isEditorMode ? _onTapUpInEditorMode : _onTapUpInGameMode;
    map.onDragStart = (int button, Vector2 position) {
      context.read<HoverContentState>().hide();
      if (button == kPrimaryButton) {
        isEditorMode
            ? _onDragUpdateInEditorMode(position)
            : _onDragUpdateInGameMode(position);
      } else if (button == kSecondaryButton) {
        cursorState = MouseCursorState.drag;
      }
      return null;
    };
    map.onDragUpdate = (int button, Vector2 position, Vector2 delta) {
      if (button == kPrimaryButton) {
        isEditorMode
            ? _onDragUpdateInEditorMode(position)
            : _onDragUpdateInGameMode(position);
      } else if (button == kSecondaryButton) {
        camera.moveBy(-camera.localToGlobal(delta) / camera.zoom);
      }
    };
    map.onDragEnd = (int button, Vector2 offset) {
      if (map.isStandby) {
        cursorState = MouseCursorState.sandglass;
      } else {
        cursorState = MouseCursorState.normal;
      }
    };

    world.add(map);

    fps = FpsComponent();

    mainTimer = Timer(
      kTimeFlowInterval / 1000,
      repeat: true,
      onTick: _autoUpdateGame,
    );
  }

  @override
  void onEnd() {
    super.onEnd();

    map.saveComponentsFrameData();

    // 清理跟随状态
    _stopFollowing();
  }

  void _addCloud() {
    if (map.terrains.isEmpty) {
      engine.error('无法在大地图 ${map.id} 上添加云朵，地形列表为空');
      return;
    }
    final cloud = ParticleCloud();
    final tile = map.terrains.random;
    cloud.position = tile.position;
    world.add(cloud);
  }

  /// start & end are flame game canvas world position.
  // void _useMapSkillFlyingSword(Vector2 start, Vector2 end) {
  //   final swordAnim = FlyingSword(start: start, end: end);
  //   map.add(swordAnim);
  // }

  void addCityToSect(dynamic city, dynamic sect) {
    final currentSectId = city['sectId'];
    if (currentSectId == sect['id']) return;
    if (currentSectId != null) {
      final currentSect = GameData.getSect(currentSectId);
      removeCityFromSect(city, currentSect);
    }

    engine.hetu.invoke('addLocationToSect', positionalArgs: [
      city,
      sect,
    ], namedArgs: {
      'incurIncident': false,
    });

    final terrainIndexes = city['territoryIndexes'];
    for (final index in terrainIndexes) {
      map.zoneColors[kColorModeNation][index] =
          HexColor.fromString(sect['color']);
    }
  }

  void removeCityFromSect(dynamic city, dynamic sect) {
    engine.hetu.invoke('removeLocationFromSect', positionalArgs: [
      city,
      sect,
    ], namedArgs: {
      'incurIncident': false,
    });

    final terrainIndexes = city['territoryIndexes'];
    for (final index in terrainIndexes) {
      map.zoneColors[kColorModeNation].remove(index);
    }
  }

  void _onTapDownInEditorMode(int button, Vector2 position) {
    if (!gameState.isInteractable) return;

    _focusNode.requestFocus();
    if (button == kPrimaryButton) {
      final tilePosition = map.worldPosition2Tile(position);
      final terrain = map.trySelectTile(tilePosition.left, tilePosition.top);
      _setSelectedTerrain(terrain);
      if (terrain != null) {
        final toolId = context.read<WorldMapState>().selectedToolId;
        if (toolId != null) {
          _paintTile(toolId, terrain);
        } else if (territoryMode != null) {
          if (terrain.locationId != null) {
            final location = GameData.getLocation(terrain.locationId);
            if (location['category'] == 'city') {
              addCityToSect(terrain, territoryMode);
            }
          }
        }
      }
    }
  }

  void _paintTile(String toolId, TileMapTerrain tile) {
    switch (toolId) {
      case 'delete':
        tile.clearAllSprite();
        tile.kind = kTerrainKindVoid;
      case 'isNotEnterable':
        tile.isNonEnterable = true;
      case 'isEnterable':
        tile.isNonEnterable = false;
      default:
        assert(GameData.tiles.containsKey(toolId));
        final toolItemData = GameData.tiles[toolId]!;
        switch (toolItemData['type']) {
          case 'terrain':
            final HTStruct spriteData =
                engine.hetu.interpreter.createStructfromJSON({
              'spriteIndex': toolItemData['spriteIndex'],
              'sprite': null,
            });
            if (toolItemData['kind'] != null) {
              tile.kind = toolItemData['kind'];
            }
            tile.overrideSpriteData(spriteData);
          case 'sprite':
            final HTStruct spriteData =
                engine.hetu.interpreter.createStructfromJSON({
              'spriteIndex': toolItemData['spriteIndex'],
              'sprite': toolItemData['sprite'],
            });
            if (toolItemData['kind'] != null) {
              tile.kind = toolItemData['kind'];
            }
            tile.overrideSpriteData(spriteData);
          case 'overlaySprite':
            final HTStruct overlayData =
                engine.hetu.interpreter.createStructfromJSON({
              'overlaySprite': toolItemData['overlaySprite'],
            });
            tile.overrideSpriteData(overlayData, isOverlay: true);
          case 'component':
            if (!map.components.values.any(
                (component) => component.tilePosition == tile.tilePosition)) {
              final componentData = GameData.mapComponents[toolId];
              final obj =
                  engine.hetu.invoke('createMapComponent', positionalArgs: [
                componentData,
                tile.tilePosition.left,
                tile.tilePosition.top,
              ]);
              map.loadComponentFromData(obj, animateOnlyWhenHeroWalking: false);
            }
        }
    }
  }

  Future<void> _onDragUpdateInEditorMode(Vector2 position) async {
    final tilePosition = map.worldPosition2Tile(position);
    final tile = map.getTerrain(tilePosition.left, tilePosition.top);
    if (tile == null) return;
    final toolId = context.read<WorldMapState>().selectedToolId;
    if (toolId != null) {
      _paintTile(toolId, tile);
    }
  }

  void _onTapUpInEditorMode(int button, Vector2 position) {
    if (!gameState.isInteractable) return;

    _focusNode.requestFocus();
    final tilePosition = map.worldPosition2Tile(position);
    final selectedTerrain = map.getTerrain(tilePosition.left, tilePosition.top);
    // if (map.trySelectTile(tilePosition.left, tilePosition.top)) {
    //   _setSelectedTerrain(map.selectedTerrain);
    // }
    if (selectedTerrain == null) return;
    cursorState = MouseCursorState.normal;
    if (button == kSecondaryButton) {
      context.read<WorldMapState>().clearTool();
      territoryMode = null;
      final tileRenderPosition = map.selectedTerrain!.topRight;
      final screenPosition = worldPosition2Screen(tileRenderPosition);
      showFluentMenu(
        cursor: GameUI.cursor,
        position: screenPosition.toOffset(),
        items: {
          engine.locale('checkInformation'):
              TerrainPopUpMenuItems.checkInformation,
          engine.locale('setTerrainKind'): {
            engine.locale('void'): TerrainPopUpMenuItems.empty,
            engine.locale('plain'): TerrainPopUpMenuItems.plain,
            engine.locale('mountain'): TerrainPopUpMenuItems.mountain,
            engine.locale('forest'): TerrainPopUpMenuItems.forest,
            engine.locale('road'): TerrainPopUpMenuItems.road,
            engine.locale('shore'): TerrainPopUpMenuItems.shore,
            engine.locale('shore'): TerrainPopUpMenuItems.shelf,
            engine.locale('lake'): TerrainPopUpMenuItems.lake,
            engine.locale('sea'): TerrainPopUpMenuItems.sea,
            engine.locale('river'): TerrainPopUpMenuItems.river,
          },
          // engine.locale('createLocation'):
          //     TerrainPopUpMenuItems.createLocation,
          engine.locale('setTerritory'): TerrainPopUpMenuItems.setTerritory,
          engine.locale('clearTerritory'): TerrainPopUpMenuItems.clearTerritory,
          engine.locale('bindLocation'): TerrainPopUpMenuItems.bindLocation,
          engine.locale('clearLocation'): TerrainPopUpMenuItems.clearLocation,
          '___1': null,
          engine.locale('clearTerrainSprite'):
              TerrainPopUpMenuItems.clearTerrainSprite,
          engine.locale('clearTerrainAnimation'):
              TerrainPopUpMenuItems.clearTerrainAnimation,
          engine.locale('clearTerrainOverlaySprite'):
              TerrainPopUpMenuItems.clearTerrainOverlaySprite,
          engine.locale('clearTerrainOverlayAnimation'):
              TerrainPopUpMenuItems.clearTerrainOverlayAnimation,
          '___2': null,
          engine.locale('bindObject'): TerrainPopUpMenuItems.bindObject,
          engine.locale('clearObject'): TerrainPopUpMenuItems.clearObject,
          engine.locale('clearDecoration'):
              TerrainPopUpMenuItems.clearDecoration,
        },
        onSelectedItem: (TerrainPopUpMenuItems item) async {
          switch (item) {
            case TerrainPopUpMenuItems.checkInformation:
              showDialog(
                  context: context,
                  builder: (context) => const TileDetailPanel());
            // case TerrainPopUpMenuItems.createLocation:
            case TerrainPopUpMenuItems.setTerritory:
              final sectId = await GameLogic.selectSectId();
              if (sectId == null) return;
              final sect = GameData.getSect(sectId);
              territoryMode = sect;
              cursorState = MouseCursorState.click;
            case TerrainPopUpMenuItems.clearTerritory:
              if (selectedTerrain.locationId != null) {
                final location =
                    GameData.getLocation(selectedTerrain.locationId);
                if (location['category'] == 'city' &&
                    selectedTerrain.nationId != null) {
                  final sect = GameData.getSect(selectedTerrain.nationId);
                  removeCityFromSect(location, sect);
                }
              }
            case TerrainPopUpMenuItems.bindLocation:
              final locationId = await GameLogic.selectLocationId();
              if (locationId == null) return;
              selectedTerrain.locationId = locationId;
              final location = GameData.getLocation(locationId);
              selectedTerrain.caption = location['name'];
            case TerrainPopUpMenuItems.clearLocation:
              selectedTerrain.locationId = null;
              selectedTerrain.caption = null;
            case TerrainPopUpMenuItems.bindObject:
              final value = await showDialog(
                context: context,
                builder: (context) => const InputStringDialog(),
              );
              if (value == null) return;
              final hasObject =
                  engine.hetu.invoke('hasObject', positionalArgs: [value]);
              if (hasObject) {
                selectedTerrain.objectId = value;
                selectedTerrain.caption = value;
              } else {
                dialog.pushDialog('objectIdNonExist', interpolations: [value]);
                dialog.execute();
                return;
              }
            case TerrainPopUpMenuItems.clearObject:
              selectedTerrain.objectId = null;
              selectedTerrain.caption = null;
            case TerrainPopUpMenuItems.clearDecoration:
              map.components.removeWhere((id, component) {
                if (component.tilePosition == tilePosition) {
                  engine.hetu.invoke('removeMapComponentByPosition',
                      positionalArgs: [tilePosition.left, tilePosition.top]);
                  component.removeFromParent();
                  return true;
                }
                return false;
              });
            case TerrainPopUpMenuItems.empty:
              selectedTerrain.kind = kTerrainKindVoid;
            case TerrainPopUpMenuItems.plain:
              selectedTerrain.kind = kTerrainKindPlain;
            case TerrainPopUpMenuItems.mountain:
              selectedTerrain.kind = kTerrainKindMountain;
            case TerrainPopUpMenuItems.forest:
              selectedTerrain.kind = kTerrainKindForest;
            case TerrainPopUpMenuItems.shore:
              selectedTerrain.kind = kTerrainKindShore;
            case TerrainPopUpMenuItems.shelf:
              selectedTerrain.kind = kTerrainKindShelf;
            case TerrainPopUpMenuItems.lake:
              selectedTerrain.kind = kTerrainKindLake;
            case TerrainPopUpMenuItems.sea:
              selectedTerrain.kind = kTerrainKindSea;
            case TerrainPopUpMenuItems.river:
              selectedTerrain.kind = kTerrainKindRiver;
            case TerrainPopUpMenuItems.road:
              selectedTerrain.kind = kTerrainKindRoad;
            case TerrainPopUpMenuItems.city:
              selectedTerrain.kind = kTerrainKindCity;
            case TerrainPopUpMenuItems.clearTerrainSprite:
              selectedTerrain.clearSprite();
              selectedTerrain.kind = kTerrainKindVoid;
            case TerrainPopUpMenuItems.clearTerrainAnimation:
              selectedTerrain.clearAnimation();
            case TerrainPopUpMenuItems.clearTerrainOverlaySprite:
              selectedTerrain.clearOverlaySprite();
            case TerrainPopUpMenuItems.clearTerrainOverlayAnimation:
              selectedTerrain.clearOverlayAnimation();
          }
          // _setSelectedTerrain(map.selectedTerrain);
        },
      );
    }
  }

  Future<void> _onAfterLoadedInEditorMode() async {
    _focusNode.requestFocus();

    await _updateWorldMapNpcs();
    _loadWorldMapCaptions();
    map.moveCameraToTilePosition(
      map.tileMapWidth ~/ 2,
      map.tileMapHeight ~/ 2,
      animated: false,
    );
  }

  Future<void> _updateWorldMapNpcs({bool updateNpcMove = false}) async {
    final toBeRemoved = [];
    for (final obj in map.components.values) {
      if (obj == map.hero) continue;
      if (!obj.isCharacter) continue;

      if (obj.data['worldId'] != map.id ||
          obj.data['worldPosition'] == null ||
          obj.data['locationId'] != null) {
        toBeRemoved.add(obj.id);
      }
    }
    for (final id in toBeRemoved) {
      map.removeTileMapComponentById(id);
    }

    charactersOnWorldMap = GameData.getNpcsOnWorldMap();
    for (final char in charactersOnWorldMap) {
      TileMapComponent charObj;
      if (map.components.values
          .any((component) => component.data['id'] == char['id'])) {
        charObj = map.components[char['id']]!;
        if (charObj.tilePosition.left != char['worldPosition']['left'] ||
            charObj.tilePosition.top != char['worldPosition']['top']) {
          int left = char['worldPosition']['left'];
          int top = char['worldPosition']['top'];
          charObj.tilePosition = TilePosition(left, top);
          if (!charObj.isWalking) {
            map.updateTileInfo(charObj);
          }
        }
      } else {
        int left = char['worldPosition']['left'];
        int top = char['worldPosition']['top'];
        charObj = await map.loadComponentFromData(
          char,
          isCharacter: true,
          srcSize: kCharacterAnimationSize,
          srcOffset: kTileOffset,
          animateOnlyWhenHeroWalking: true,
        );
        charObj.tilePosition = TilePosition(left, top);
        map.updateTileInfo(charObj);
      }

      if (updateNpcMove) {
        // 非玩家控制角色，第一次出现在大地图上，必有一个移动目标
        final moveTo = char['worldPosition']['moveTo'];
        assert(moveTo != null && moveTo['locationId'] != null,
            'Character ${char['id']} 在大地图 ${worldData['id']} 上缺少 moveTo 数据');
        final List<int> route = moveTo['route'];
        assert(route.isNotEmpty);
        if (!charObj.isWalking) {
          final tileIndex = route.first;
          final tilePosition = map.index2TilePosition(tileIndex);
          charObj.tilePosition = tilePosition;
          route.removeAt(0);
          if (route.isEmpty) {
            moveTo['route'] = null;
            char['locationId'] = moveTo['locationId'];
          } else {
            final nextIndex = route.first;
            final nextTilePosition = map.index2TilePosition(route.first);
            final nextTerrain =
                map.getTerrain(nextTilePosition.left, nextTilePosition.top);
            assert(nextTerrain != null,
                'Character ${char['id']} 在大地图 ${worldData['id']} 上的移动目标 $nextTilePosition 无效');
            double multiplier = 1.0;
            if (kTerrainKindsWater.contains(nextTerrain!.kind)) {
              multiplier = 0.5;
            } else if (kTerrainKindsMountain.contains(nextTerrain.kind)) {
              multiplier = 0.125;
            } else {
              multiplier = 0.25;
            }
            charObj.walkToTilePositionByRoute([tileIndex, nextIndex],
                speedMultiplier: multiplier,
                onStepCallback: (terrain, next, isFinished) {
              if (isFinished) {
                final worldPosition = charObj.data['worldPosition'];
                worldPosition['left'] = terrain.left;
                worldPosition['top'] = terrain.top;
                worldPosition['moveTo']['lastMoveTimestamp'] =
                    GameData.game['timestamp'];
                if (terrain.tilePosition == map.hero?.tilePosition) {
                  _updateNpcsAtHeroPosition();
                }
              }
              return false;
            });
          }
        }
      }
    }
  }

  Future<void> _updateNpcsAtHeroPosition() async {
    if (GameData.hero == null) return;

    final npcs = [];
    for (final id in GameData.hero['companions']) {
      final charData = GameData.getCharacter(id);
      npcs.add(charData);
    }
    final characters = GameData.getNpcsAtWorldMapPosition(
        GameData.hero['worldPosition']['left'],
        GameData.hero['worldPosition']['top'],
        worldId: GameData.hero['worldId']);
    npcs.addAll(characters);
    gameState.updateNpcs(npcs);
  }

  void _setWorldMapCaption(int left, int top, String caption, [Color? color]) {
    map.setTerrainCaption(
      left,
      top,
      caption,
      TextStyle(
        fontSize: 7,
        fontFamily: GameUI.fontFamily,
        color: color ?? Colors.white,
      ),
    );
  }

  void _loadWorldMapCaptions() {
    final locations = GameData.game['locations'].values;
    for (final location in locations) {
      if (location['worldId'] == worldData['id'] &&
          location['terrainIndex'] != null &&
          location['isDiscovered'] == true) {
        final int left = location['worldPosition']['left'];
        final int top = location['worldPosition']['top'];
        _setWorldMapCaption(left, top, location['name'],
            location['category'] == 'city' ? Colors.yellow : Colors.white70);
      }
    }
  }

  void _loadWorldMapObjects() {
    for (final object in worldData['objects'].values) {
      if (object['category'] == 'enemy') {
        final entity = object['battleEntity'];
        _characterSetToWorldPosition(
          entity,
          entity['worldPosition']['left'],
          entity['worldPosition']['top'],
        );
      }
    }
  }

  void _tryEnterLocation(dynamic location) async {
    gameState.isInteractable = false;

    if (location['isDiscovered'] != true) {
      await engine.hetu.invoke('discoverLocation', positionalArgs: [
        location
      ], namedArgs: {
        'updateWorldMap': true,
      });
      dialog.pushDialog('hint_discoveredLocation',
          interpolations: location['name']);
      await dialog.execute();
      final int left = location['worldPosition']['left'];
      final int top = location['worldPosition']['top'];
      _setWorldMapCaption(left, top, location['name'],
          location['category'] == 'city' ? Colors.white : Colors.green);
    }

    GameLogic.tryEnterLocation(location);
  }

  void _characterSetToWorldPosition(dynamic character, int left, int top,
      {String? direction}) async {
    late TileMapComponent charComponent;
    final charId = character['id'];
    if (character['id'] == map.hero?.id) {
      charComponent = map.hero!;
      assert(character == map.hero?.data);
      if (!map.components.containsKey(charId)) {
        map.add(charComponent);
        map.components[charId] = charComponent;
      }
    } else {
      if (map.components.containsKey(charId)) {
        charComponent = map.components[charId]!;
      } else {
        charComponent = await map.loadComponentFromData(
          character,
          isCharacter: true,
          srcSize: kCharacterAnimationSize,
          srcOffset: kTileOffset,
          animateOnlyWhenHeroWalking: true,
        );
      }
    }
    final terrain = map.getTerrain(left, top);
    if (terrain != null) {
      charComponent.isOnWater = terrain.isWater;
    }
    charComponent.tilePosition = TilePosition(left, top);
    OrthogonalDirection dir;
    if (direction != null) {
      dir = OrthogonalDirection.values
          .singleWhere((element) => element.name == direction);
    } else {
      dir = OrthogonalDirection.south;
    }
    charComponent.setDirection(dir);
    map.updateTileInfo(charComponent);
    if (character == map.hero?.data) {
      _updateHeroAtTerrain();
    }
  }

  Future<bool> _onHeroStepOnMap(
      TileMapTerrain terrain, TileMapTerrain? next, bool isFinished) async {
    if (next != null) {
      if (next.objectId != null) {
        // 如果下一个格子有物体，且该物体 blockMove 为 true
        // 意味着该物体会阻挡移动
        final objectsData = engine.hetu.fetch('objects', namespace: 'world');
        final objectData = objectsData[next.objectId];
        if (objectData['blockMove'] == true) {
          map.hero!.isWalkCanceled = true;
          engine.hetu.invoke('onInteractMapObject',
              positionalArgs: [objectData, next.data]);
        }
      }

      if (next.priority > map.hero!.priority) {
        map.hero!.priority = next.priority + 5;
      }
    }

    if (map.hero?.prevRouteNode != null) {
      /// 实际移动一格后的回调
      map.lightUpAroundTile(
        terrain.tilePosition,
        size: map.hero!.data['stats']['lightRadius'],
      );
      final result = await engine.hetu.invoke('onWorldEvent',
          positionalArgs: ['onAfterMove', terrain.data]);
      if (result == true) {
        map.hero!.isWalkCanceled = true;
      }
      // TODO: 某些情况下，让英雄返回上一格
      // map.objectWalkToPreviousTile(map.hero!);

      double staminaCost;
      double speed;
      int timeCost;
      if (kTerrainKindsMountain.contains(terrain.kind)) {
        staminaCost = GameData.hero['stats']['staminaCostOnMountain'];
        speed = GameData.hero['stats']['speedOnMountain'];
      } else if (kTerrainKindsWater.contains(terrain.kind)) {
        staminaCost = GameData.hero['stats']['staminaCostOnWater'];
        speed = GameData.hero['stats']['speedOnWater'];
      } else {
        staminaCost = 0.0;
        speed = GameData.hero['stats']['speedOnPlain'];
      }
      timeCost = (kTicksPerTime / speed).round();
      if (isMainWorld) {
        await GameLogic.updateGame(ticks: timeCost, worldMap: this);
      }
      await _updateWorldMapNpcs(updateNpcMove: true);

      if (staminaCost > 0) {
        final isDying = engine.hetu.invoke('setLife',
            namespace: 'Player',
            positionalArgs: [GameData.hero['life'] - staminaCost]);

        addHintTextOnTile('${engine.locale('stamina')} -${staminaCost.round()}',
            terrain.left, terrain.top,
            color: Colors.red);
        gameState.updateUI();
        if (isDying) {
          map.hero!.isWalkCanceled = true;
          GameLogic.onDying();
          return false;
        }
      }
    }

    if (isFinished) {
      engine.hetu.invoke('setCharacterWorldPosition', positionalArgs: [
        GameData.hero,
        map.hero!.tilePosition.left,
        map.hero!.tilePosition.top
      ]);
      await _updateHeroAtTerrain(tile: terrain, animated: true, notify: false);
      await _updateNpcsAtHeroPosition();

      if (map.hero!.isWalkCanceled) return false;

      // debugPrint('移动完成，检查跟随状态: $_followingTargetId');

      // 检查是否处于跟随状态
      // 跟随状态下不执行其他交互逻辑
      if (_followingTargetId != null) {
        engine.info('继续跟随下一格');
        await _continueFollowing();
        // 返回 true，表示取消移动完成相关逻辑，继续移动
        return true;
      } else {
        if (next != null) {
          if (next.objectId != null) {
            GameLogic.tryInteractObject(next.objectId!, next.data);
          }
        } else {
          if (terrain.objectId != null) {
            GameLogic.tryInteractObject(terrain.objectId!, terrain.data);
          } else if (terrain.objectId != null) {
            GameLogic.tryInteractObject(terrain.objectId!, terrain.data);
          } else if (terrain.locationId != null) {
            final location = GameData.getLocation(terrain.locationId);
            _tryEnterLocation(location);
          }
        }
      }
    }

    return false;
  }

  void _heroMoveTo(TileMapTerrain terrain) async {
    if (!terrain.isLighted && map.showFogOfWar) return;
    final hero = map.hero!;
    if (hero.isWalking) {
      hero.isWalkCanceled = true;
      TileMapTerrain lastTerrain;
      if (hero.currentRoute != null) {
        final lastNode = hero.currentRoute!.last;
        lastTerrain = map.terrains[lastNode.index];
      } else {
        lastTerrain = map.getTerrain(hero.left, hero.top)!;
      }
      hero.changedRoute = await GameLogic.calculateRoute(
        fromTile: lastTerrain.data,
        toTile: terrain.data,
        isHero: true,
      );
      return;
    }

    hero.isWalkCanceled = false;
    final heroTerrain = map.getTerrain(hero.left, hero.top);
    final neighbors = map.getTileNeighbors(heroTerrain!);
    if (terrain.isNonEnterable &&
        neighbors.containsValue(terrain) &&
        terrain.objectId != null) {
      GameLogic.tryInteractObject(terrain.objectId!, terrain.data);
      return;
    } else {
      List<int>? calculatedRoute = await GameLogic.calculateRoute(
        fromTile: heroTerrain.data,
        toTile: terrain.data,
        isHero: true,
      );

      if (calculatedRoute != null) {
        assert(calculatedRoute.length > 1);
        final result = await engine.hetu
            .invoke('onWorldEvent', positionalArgs: ['onBeforeMove', terrain]);
        if (result == true) {
          return;
        }
        hero.walkToTilePositionByRoute(
          calculatedRoute,
          onStepCallback: _onHeroStepOnMap,
        );
      } else {
        engine.warning(
            '无法将英雄从大地图位置 [${hero.tilePosition}] 移动到 [${terrain.tilePosition}]');
      }
    }
  }

  /// 让主角跟随指定的NPC
  /// [targetId] NPC的id
  /// 每次英雄移动一格后，会在 _onHeroStepOnMap 中自动检查并继续跟随
  void _heroFollowTo(String targetId) async {
    if (_followingTargetId == targetId) return;

    // 如果已经在跟随其他目标，先停止
    if (_followingTargetId != null && _followingTargetId != targetId) {
      _stopFollowing();
    }

    assert(map.components[targetId] != null, '跟随目标 $targetId 不存在');

    // 设置跟随目标
    _followingTargetId = targetId;

    engine.info('开始跟随目标: $targetId');

    // 开始第一次跟随移动
    await _continueFollowing();
  }

  /// 停止跟随
  void _stopFollowing() {
    _followingTargetId = null;
  }

  /// 继续跟随移动（在每次移动完成后调用）
  Future<void> _continueFollowing() async {
    if (_followingTargetId == null) return;

    final hero = map.hero;
    assert(hero != null, '英雄对象不存在，无法跟随');

    // 等待一帧，确保之前的移动状态完全更新
    await Future.delayed(Duration.zero);

    // 英雄已经在移动
    if (hero!.isWalking) {
      return;
    }

    // 检查目标是否还在地图上
    final target = map.components[_followingTargetId];
    if (target == null) {
      // debugPrint('跟随目标 $_followingTargetId 已不在地图上');
      _stopFollowing();
      return;
    }

    // 获取当前英雄和目标的位置
    final heroTerrain = map.getTerrain(hero.left, hero.top);
    final targetTerrain = map.getTerrain(target.left, target.top);

    assert(heroTerrain != null && targetTerrain != null);

    // debugPrint(
    //     '继续跟随: 英雄位置(${hero.left}, ${hero.top}) -> 目标位置(${target.left}, ${target.top})');

    // 如果已经在同一位置，停止跟随
    if (hero.left == target.left && hero.top == target.top) {
      // debugPrint('已到达目标位置');
      _stopFollowing();
      return;
    }

    // 计算从英雄位置到目标位置的完整路径
    List<int>? route = await GameLogic.calculateRoute(
      fromTile: heroTerrain!.data,
      toTile: targetTerrain!.data,
      isHero: true,
    );

    if (route == null || route.length < 2) {
      debugPrint('到目标 $_followingTargetId 的路径计算失败或路径过短: ${route?.length}');
      _stopFollowing();
      return;
    }

    // 只取路径的前两个点（即只移动一格）
    List<int> oneStepRoute = route.take(2).toList();

    // 执行移动一格
    hero.isWalkCanceled = false;
    hero.walkToTilePositionByRoute(
      oneStepRoute,
      onStepCallback: _onHeroStepOnMap,
    );
  }

  Future<void> _onDragUpdateInGameMode(Vector2 position) async {}

  void _onTapDownInGameMode(int button, Vector2 position) {
    if (!gameState.isInteractable) return;
    context.read<HoverContentState>().hide();
    _focusNode.requestFocus();
    final tilePosition = map.worldPosition2Tile(position);
    map.trySelectTile(tilePosition.left, tilePosition.top);
  }

  void _onTapUpInGameMode(int button, Vector2 position) async {
    _focusNode.requestFocus();
    if (!gameState.isInteractable) return;
    if (_playerFreezed) return;
    if (map.hero == null) return;
    if (map.isStandby) {
      map.isStandby = false;
      cursorState = MouseCursorState.normal;
      return;
    }

    if (dialog.isOpened) {
      await dialog.execute();
    }

    final terrain = map.selectedTerrain!;
    if (button == kPrimaryButton) {
      // if (cursorState == MouseCursorState.press) {
      //   cursorState = MouseCursorState.click;
      // }
      if (terrain.tilePosition != map.hero!.tilePosition) {
        _heroMoveTo(terrain);
      } else {
        if (terrain.locationId != null) {
          final location = GameData.getLocation(terrain.locationId);
          _tryEnterLocation(location);
        } else if (terrain.objectId != null) {
          GameLogic.tryInteractObject(terrain.objectId!, terrain.data);
        }
      }
    } else if (button == kSecondaryButton) {
      if (!isMainWorld) return;

      final menuPosition = worldPosition2Screen(map.selectedTerrain!.topRight);
      if (terrain.tilePosition == map.hero!.tilePosition) {
        showFluentMenu(
          cursor: GameUI.cursor,
          position: menuPosition.toOffset(),
          items: {
            engine.locale('build'): {
              engine.locale('city'): 'buildCity',
              '___0': null,
              engine.locale('farmland'): 'buildFarmLand',
              engine.locale('fishery'): 'buildFishery',
              engine.locale('timberland'): 'buildTimberLand',
              engine.locale('mine'): 'buildMine',
              engine.locale('huntingground'): 'buildHuntingGround',
            },
            engine.locale('warMode'): 'warMode',
            '___1': null,
            engine.locale('standby'): 'standby',
          },
          onSelectedItem: (item) {
            switch (item) {
              case 'buildCity':
                {}
              case 'buildFarmLand':
                {}
              case 'buildFishery':
                {}
              case 'buildTimberLand':
                {}
              case 'buildMine':
                {}
              case 'buildHuntingGround':
                {}
              case 'warMode':
                {}
              case 'standby':
                map.isStandby = !map.isStandby;
                cursorState = map.isStandby
                    ? MouseCursorState.sandglass
                    : MouseCursorState.normal;
            }
          },
        );
      } else {
        final List<TileMapComponent> charactersHere = [];

        for (final obj in map.components.values) {
          if (obj.isCharacter && obj.id != map.hero!.id) {
            if (obj.containsPoint(position)) {
              charactersHere.add(obj);
            }
          }
        }

        showFluentMenu(
          cursor: GameUI.cursor,
          position: menuPosition.toOffset(),
          items: {
            engine.locale('moveToHere'): 'moveToHere',
            if (charactersHere.isNotEmpty)
              engine.locale('follow'): {
                for (final char in charactersHere)
                  char.data['name'] as String: char.id
              },
          },
          onSelectedItem: (String item) {
            switch (item) {
              case 'moveToHere':
                if (terrain.tilePosition != map.hero!.tilePosition) {
                  _heroMoveTo(terrain);
                }
              default:
                // 其他选项均为跟随某个NPC
                _heroFollowTo(item);
            }
          },
        );
      }
    }
  }

  void _updateWorldMapInGameMode() {
    _updateWorldMapNpcs();
    _updateHeroAtTerrain();
    _updateNpcsAtHeroPosition();
    if (map.data['useCustomLogic'] != true && map.hero != null) {
      map.lightUpAroundTile(map.hero!.tilePosition,
          size: GameData.hero['stats']['lightRadius']);
    }
  }

  Future<void> _onAfterLoadedInGameMode() async {
    _focusNode.requestFocus();
    final bool isNewGame = GameData.game['isNewGame'] ?? false;
    if (isNewGame && GameData.hero == null) {
      final Iterable characters = GameData.game['characters'].values;
      List availableCharacters;
      if (kDebugMode) {
        availableCharacters = GameData.game['characters'].values.toList();
      } else {
        availableCharacters = characters.where((character) {
          final age = engine.hetu
              .invoke('getCharacterAge', positionalArgs: [character]);
          if (age > kMaxHeroAge) {
            return false;
          }
          final int rank = character['rank'];
          if (rank > 0) {
            return false;
          }
          final sectId = character['sectId'];
          if (sectId != null) {
            return false;
          }
          final homeLocationId = character['homeLocationId'];
          assert(homeLocationId != null,
              'Character ${character['id']} has no homeLocationId!');
          final homeLocation = GameData.getLocation(homeLocationId);
          if (homeLocation['isHidden']) {
            return false;
          }
          return true;
        }).toList();
      }
      if (availableCharacters.length < _kInitialCharacterSelectionCount) {
        for (var i = availableCharacters.length;
            i < _kInitialCharacterSelectionCount;
            ++i) {
          final locations = GameData.game['locations'].values.where((data) {
            return data['category'] == 'city' && data['isDiscovered'] == true;
          }).toList()
            ..shuffle(GameData.random);
          final char = engine.hetu.invoke('Character', namedArgs: {
            'age': GameData.random.nextInt(6) + 12,
            'locationId': locations.first['id'],
          });
          availableCharacters.add(char);
        }
      }
      final key = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => InformationView(
          title: engine.locale('selectHero'),
          showCloseButton: false,
          confirmationOnSelect: true,
          mode: InformationMode.selectCharacter,
          characters: availableCharacters,
        ),
      );
      engine.hetu.invoke('setHero', positionalArgs: [key]);
      if (GameData.game['enableTutorial'] == true) {
        engine.hetu.invoke('randomizeHeroWorldPosition');
      }
      GameData.hero = engine.hetu.fetch('hero');
      final heroHomeLocation =
          GameData.getLocation(GameData.hero['homeLocationId']);
      await engine.hetu.invoke('discoverLocation', positionalArgs: [
        heroHomeLocation,
      ], namedArgs: {
        'updateWorldMap': true,
      });
    }
    assert(GameData.hero != null);

    engine.setLoading(true, tip: engine.locale(kTips.random));
    await Future.delayed(const Duration(milliseconds: 250));

    final worldInfo = GameData.getLlmChatSystemPrompt1();
    await engine.prepareLlamaBaseState(worldInfo);

    await map.loadHeroFromData(
      GameData.hero,
      srcSize: kCharacterAnimationSize,
      srcOffset: kTileOffset,
    );

    map.moveCameraToHero(animated: false);
    map.lightUpAroundTile(map.hero!.tilePosition,
        size: GameData.hero['stats']['lightRadius']);

    _loadWorldMapObjects();
    _loadWorldMapCaptions();

    _updateWorldMapInGameMode();

    if (isMainWorld) {
      for (var i = 0; i < kMaxCloudsCount ~/ 2; ++i) {
        _addCloud();
      }
    }

    if (isNewGame) {
      await engine.hetu.invoke('onNewGame');
    }

    engine.setLoading(false);
  }

  @override
  FutureOr<void> onStart([dynamic arguments = const {}]) async {
    super.onStart(arguments);

    cursorState = MouseCursorState.normal;
    GameData.world = worldData;
    gameState.isInteractable = true;

    if (worldData['isMain'] == true) {
      GameData.mainWorld = this;
    }
    GameData.currentWorld = this;

    _loadBindings();

    context.read<HoverContentState>().hide();
    context.read<ViewPanelState>().clearAll();

    engine.hetu.invoke('setCurrentWorld', positionalArgs: [worldData['id']]);
  }

  @override
  void onMount() async {
    super.onMount();

    await engine.hetu.invoke('onWorldEvent', positionalArgs: ['onEnterMap']);

    gameState.reset();

    if (_isInitializing) {
      _isInitializing = false;
    } else {
      if (isEditorMode) {
        _updateWorldMapNpcs();
      } else {
        _updateWorldMapInGameMode();
      }
    }
  }

  // TODO: 自动移动屏幕
  void _onMouseEnterScreenEdge(OrthogonalDirection direction) {
    context.read<HoverContentState>().hide();
  }

  void _onMouseEnterTile(TileMapTerrain? tile) {
    if (!gameState.isInteractable) return;
    if (map.isStandby) return;

    context.read<HoverContentState>().hide();

    bool clickable = false;
    bool talkable = false;
    if (tile != null && (tile.isLighted || !map.showFogOfWar)) {
      if (tile == gameState.currentTerrain) {
        clickable = true;
      }

      // for (final char in charactersOnWorldMap) {
      //   final worldPosition = char['worldPosition'];
      //   if (worldPosition['left'] == tile.left &&
      //       worldPosition['top'] == tile.top) {
      //     talkable = true;
      //     break;
      //   }
      // }

      if (!talkable) {
        final hoverContent = StringBuffer();
        if (tile.zoneId != null) {
          final zone = worldData['zones'][tile.zoneId];
          hoverContent.write('${zone['name']}');
        }
        hoverContent.writeln(' ${engine.locale(tile.kind)}'
            '${engine.config.debugMode ? ' <grey>#${tile.index}</>' : ''}'
            ' [${tile.left},${tile.top}]');
        if (tile.nationId != null) {
          final sect = GameData.getSect(tile.nationId);
          hoverContent.write(sect['name']);
        }

        if (tile.cityId != null) {
          final city = GameData.getLocation(tile.cityId);
          hoverContent.write(' <grey>${city['name']}</>');
        }

        if (tile.locationId != null) {
          final location = GameData.getLocation(tile.locationId);
          if (location['isDiscovered']) {
            hoverContent.writeln('');
            if (location['category'] == 'city' && engine.config.debugMode) {
              hoverContent.writeln('${engine.locale('city')}'
                  ' <grey>${engine.locale('development')}: ${location['development']},'
                  ' ${engine.locale('residents')}: ${location['residents'].length}</>');
            } else {
              if (engine.config.debugMode) {
                hoverContent.writeln('${location['name']}'
                    ' <grey>${engine.locale('development')}: ${location['development']}</>');
              }
            }
            clickable = true;
          }
        } else if (tile.objectId != null) {
          final objects = engine.hetu.fetch('objects', namespace: 'world');
          final object = objects[tile.objectId!];
          assert(object != null, 'objectId: ${tile.objectId} not found!');

          final objectHoverContent = object?['hoverContent'] ?? '';
          hoverContent.writeln(objectHoverContent);
          if (engine.config.debugMode) {
            hoverContent.writeln('<grey>${object['id']}</>');
          }
          clickable = true;
        } else {
          hoverContent.writeln('');
        }

        // if (kDebugMode) {
        //   final renderPosition = tile.position;
        //   final screenPosition = worldPosition2Screen(renderPosition);
        //   hoverContent.writeln(
        //       '<grey>renderPosition: (${renderPosition.x.toStringAsFixed(1)},${renderPosition.y.toStringAsFixed(1)})</>');
        //   hoverContent.writeln(
        //       '<grey>screenPosition: (${screenPosition.x.toStringAsFixed(1)},${screenPosition.y.toStringAsFixed(1)})</>');
        // }

        final content = hoverContent.toString();
        if (content.isNotBlank) {
          final screenPosition = worldPosition2Screen(tile.position);
          context.read<HoverContentState>().show(
                content,
                Rect.fromLTWH(
                  screenPosition.x + map.tileOffset.x * camera.zoom,
                  screenPosition.y + map.tileOffset.y * camera.zoom,
                  tile.width * camera.zoom,
                  tile.height * camera.zoom,
                ),
                direction: HoverContentDirection.topCenter,
              );
        }
      }

      // if (talkable) {
      //   cursorState = MouseCursorState.talk;
      // } else

      if (clickable) {
        cursorState = MouseCursorState.click;
      } else if (map.isStandby) {
        cursorState = MouseCursorState.sandglass;
      } else {
        cursorState = MouseCursorState.normal;
      }
    } else {
      context.read<HoverContentState>().hide();

      if (map.isStandby) {
        cursorState = MouseCursorState.sandglass;
      } else {
        cursorState = MouseCursorState.normal;
      }
    }
  }

  void _autoUpdateGame() {
    schedule(() async {
      await GameLogic.updateGame(ticks: kTicksPerTime, worldMap: this);
      _updateWorldMapNpcs(updateNpcMove: true);
      _updateNpcsAtHeroPosition();
    });
  }

  void addHintTextOnTile(
    String text,
    int left,
    int top, {
    double duration = 1.5,
    Color? color,
  }) {
    final worldPosition = map.tilePosition2TileCenter(left, top);
    // final screenPosition = map.worldPosition2Screen(worldPosition);

    addHintText(
      text,
      position: worldPosition,
      horizontalVariation: 10.0,
      verticalVariation: 10.0,
      offsetY: 20.0,
      duration: duration,
      textStyle: TextStyle(
        color: color ?? Colors.white,
        fontSize: 8,
        fontFamily: GameUI.fontFamily,
      ),
      onViewport: false,
    );
  }

  Future<void> promptTextBanner(String text) async {
    final prompt = PromptTextBanner(
      text: text,
      backgroundColor: GameUI.backgroundColor2,
      position: center,
    );
    camera.viewport.add(prompt);
    await prompt.fadeIn(duration: 0.8);
    await Future.delayed(Duration(milliseconds: 500));
    await prompt.fadeOut(duration: 1.0);
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          engine.warning('keydown: ${event.logicalKey.debugName}');
          switch (event.logicalKey) {
            case LogicalKeyboardKey.space:
              camera.zoom = 2.0;
              if (isEditorMode) {
                // map.moveCameraToTileMapCenter();
              } else {
                map.moveCameraToHero();
              }
            case LogicalKeyboardKey.escape:
              if (isEditorMode) {
                context.read<WorldMapState>().clearTool();

                if (territoryMode != null) {
                  territoryMode = null;
                  cursorState = MouseCursorState.normal;
                }
              }

              if (map.hero != null) {
                if (map.hero!.isWalking) {
                  map.hero!.isWalkCanceled = true;
                }

                _stopFollowing();
              }
            case LogicalKeyboardKey.keyW:
              camera.moveBy(Vector2(0, -10));
            case LogicalKeyboardKey.keyS:
              camera.moveBy(Vector2(0, 10));
            case LogicalKeyboardKey.keyA:
              camera.moveBy(Vector2(-10, 0));
            case LogicalKeyboardKey.keyD:
              camera.moveBy(Vector2(10, 0));
          }
        } else if (event is KeyRepeatEvent) {
          engine.warning('key repeat: ${event.logicalKey.debugName}');
          switch (event.logicalKey) {
            case LogicalKeyboardKey.keyW:
              camera.moveBy(Vector2(0, -10));
            case LogicalKeyboardKey.keyS:
              camera.moveBy(Vector2(0, 10));
            case LogicalKeyboardKey.keyA:
              camera.moveBy(Vector2(-10, 0));
            case LogicalKeyboardKey.keyD:
              camera.moveBy(Vector2(10, 0));
          }
        }
      },
      child: Stack(
        children: [
          SceneWidget(
            scene: this,
            loadingBuilder: loadingBuilder,
            overlayBuilderMap: overlayBuilderMap,
            initialActiveOverlays: initialActiveOverlays,
          ),
          if (!isEditorMode) ...[
            GameUIOverlay(
              showNpcs: true,
              showJournal: true,
              actions: [
                if (isMainWorld) ViewModeMenuButton(map: map),
                DropMenuButton(map: map),
              ],
            ),
          ] else ...[
            Positioned(
              right: 32,
              top: 0,
              child: ViewModeMenuButton(map: map),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: DropMenuButton(
                map: map,
                isEditorMode: true,
              ),
            ),
            EntityListPanel(
              size: Size(390, GameUI.size.y),
              onUpdateCharacters: _updateWorldMapNpcs,
              onUpdateLocations: _loadWorldMapCaptions,
              onCreatedSect: (sect, location) {
                final territoryIndexes = location['territoryIndexes'];
                for (final index in territoryIndexes) {
                  map.zoneColors[kColorModeNation][index] =
                      HexColor.fromString(sect['color']);
                }
              },
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Toolbox(),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: LocationPanel(
                width: 390.0,
                height: 200.0,
                isEditorMode: true,
              ),
            )
          ],
        ],
      ),
    );
  }
}
