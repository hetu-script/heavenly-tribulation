import 'dart:async';

import 'package:flame/effects.dart';
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

import '../../engine.dart';
import 'particles/cloud.dart';
import 'particles/rubble.dart';
import '../common.dart';
import '../../ui.dart';
import '../../data/game.dart';
import '../../state/states.dart';
import '../game_dialog/game_dialog_content.dart';
import '../../widgets/ui_overlay.dart';
import '../../widgets/dialog/input_string.dart';
import '../../widgets/information.dart';
import '../../widgets/ui/menu_builder.dart';
import 'widgets/entity_list.dart';
import 'widgets/tile_detail.dart';
import 'widgets/toolbox.dart';
import '../../logic/logic.dart';
import 'components/banner.dart';
import '../../data/common.dart';
import 'widgets/location_panel.dart';
import 'widgets/drop_menu.dart';

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

enum WorldMapPopUpMenuItems {
  terrainInformation,
  buildFarmLand,
  buildFishery,
  buildTimberLand,
  buildMine,
  buildHuntingGround,
  warMode,
}

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
  viewOrganizations,
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

class WorldMapScene extends Scene {
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
          captionStyle: GameUI.captionStyle,
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

  set cursorState(MouseCursorState cursorState) {
    switch (cursorState) {
      case MouseCursorState.normal:
        mouseCursor = GameUI.cursor.resolve({});
      case MouseCursorState.click:
        mouseCursor = GameUI.cursor.resolve({WidgetState.hovered});
      case MouseCursorState.drag:
        mouseCursor = GameUI.cursor.resolve({WidgetState.dragged});
    }
  }

  final TileMap map;

  final dynamic worldData;

  final bool isEditorMode;

  bool get isMainWorld => worldData['isMain'] ?? false;

  late FpsComponent fps;

  final menuController = fluent.FlyoutController();

  dynamic territoryMode;

  bool _playerFreezed = false;
  set playerFreezed(bool value) {
    _playerFreezed = map.autoUpdateComponent = value;
  }

  // TileMapTerrain? _selectedTerrain;
  // dynamic _selectedZone;
  // dynamic _selectedNation;
  // dynamic _selectedLocation;

  // void _setSelectedTerrain(TileMapTerrain? terrain) {
  //   _selectedTerrain = terrain;
  //   if (_selectedTerrain == null) return;

  //   final zoneId = selectedTerrain.zoneId;
  //   if (zoneId != null) {
  //     _selectedZone =
  //         engine.hetu.invoke('getZoneById', positionalArgs: [zoneId]);
  //   } else {
  //     _selectedZone = null;
  //   }

  //   final nationId = selectedTerrain.nationId;
  //   if (nationId != null) {
  //     _selectedNation =
  //         engine.hetu.invoke('getOrganizationById', positionalArgs: [nationId]);
  //   } else {
  //     _selectedNation = null;
  //   }

  //   final String? locationId = selectedTerrain.locationId;
  //   if (locationId != null) {
  //     _selectedLocation = GameData.getLocation(locationId);
  //   } else {
  //     _selectedLocation = null;
  //   }

  //   context.read<SelectedPositionState>().update(
  //         currentZoneData: _selectedZone,
  //         currentNationData: _selectedNation,
  //         currentLocationData: _selectedLocation,
  //         currentTerrainObject: _selectedTerrain,
  //       );
  // }

  Future<void> _updateHeroTerrain({
    TileMapTerrain? tile,
    bool moveCameraToHero = true,
    bool animated = false,
  }) async {
    if (map.hero == null) return;

    final terrain = tile ?? map.getHeroAtTerrain();
    if (terrain == null) return;

    dynamic heroAtZone;
    dynamic heroAtNation;
    // dynamic heroAtLocation;

    final zoneId = terrain.zoneId;
    if (zoneId != null) {
      heroAtZone = engine.hetu.invoke('getZoneById', positionalArgs: [zoneId]);
    } else {
      heroAtZone = null;
    }
    final nationId = terrain.nationId;
    if (nationId != null) {
      heroAtNation =
          engine.hetu.invoke('getOrganizationById', positionalArgs: [nationId]);
    } else {
      heroAtNation = null;
    }
    // final String? locationId = terrain.locationId;
    // if (locationId != null) {
    //   heroAtLocation = GameData.getLocation(locationId);
    // } else {
    //   heroAtLocation = null;
    // }
    context.read<HeroPositionState>().updateTerrain(
          currentZoneData: heroAtZone,
          currentNationData: heroAtNation,
          currentTerrainData: terrain,
        );
    // context.read<HeroPositionState>().updateLocation(heroAtLocation);

    if (moveCameraToHero) {
      await map.moveCameraToHero(animated: animated);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);

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
      cursorState = MouseCursorState.normal;
    };

    world.add(map);

    fps = FpsComponent();

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

    // engine.hetu.interpreter.bindExternalFunction('World::clearTerrainSprite', (
    //     {positionalArgs, namedArgs}) {
    //   final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
    //   tile?.clearSprite();
    // }, override: true);

    // engine.hetu.interpreter.bindExternalFunction('World::clearTerrainAnimation',
    //     ({positionalArgs, namedArgs}) {
    //   final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
    //   tile?.clearAnimation();
    // }, override: true);

    // engine.hetu.interpreter.bindExternalFunction(
    //     'World::clearTerrainOverlaySprite', ({positionalArgs, namedArgs}) {
    //   final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
    //   tile?.clearOverlaySprite();
    // }, override: true);

    // engine.hetu.interpreter.bindExternalFunction(
    //     'World::clearTerrainOverlayAnimation', ({positionalArgs, namedArgs}) {
    //   final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
    //   tile?.clearOverlayAnimation();
    // }, override: true);

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
      final character = map.components[positionalArgs[0]];
      if (character == null) {
        engine.warn('大地图对象 id [${positionalArgs[0]}] 不存在');
        return null;
      }
      character.isWalkCanceled = false;
      final completer = Completer();
      final int toX = positionalArgs[1];
      final int toY = positionalArgs[2];
      final String? endDirString = namedArgs['endDirection'];
      OrthogonalDirection? finishMoveDirection;
      if (endDirString != null) {
        finishMoveDirection = OrthogonalDirection.values
            .singleWhere((element) => element.name == endDirString);
      }
      final HTFunction? onStepCallback = namedArgs['onStepCallback'];

      final route = await _calculateRoute(
          fromX: character.left, fromY: character.top, toX: toX, toY: toY);
      if (route != null) {
        assert(route.length > 1);
        map.componentWalkToTilePositionByRoute(
          character,
          List<int>.from(route),
          finishMoveDirection: finishMoveDirection,
          onStepCallback: (terrain, next, isFinished) {
            onStepCallback?.call(positionalArgs: [terrain.data, next?.data]);
            completer.complete();
            map.updateTileInfo(character);
          },
        );
      } else {
        engine.error(
            '无法将对象 ${character.id} 从大地图位置 [${character.tilePosition}] 移动到 [$toX, $toY]}');
        completer.complete();
      }
      return completer.future;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::setObjectTo', (
        {positionalArgs, namedArgs}) {
      final object = map.components[positionalArgs[0]];
      if (object == null) {
        engine.warn(
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
        ({positionalArgs, namedArgs}) => _updateWorldMapCaptions(),
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
  }

  @override
  void onEnd() {
    super.onEnd();

    map.saveComponentsFrameData();
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

  void addCityToOrganization(dynamic city, dynamic organization) {
    final currentOrganizationId = city['organizationId'];
    if (currentOrganizationId == organization['id']) return;
    if (currentOrganizationId != null) {
      final currentOrganization =
          GameData.getOrganization(currentOrganizationId);
      removeCityFromOrganization(city, currentOrganization);
    }

    engine.hetu.invoke('addLocationToOrganization', positionalArgs: [
      city,
      organization,
    ], namedArgs: {
      'incurIncident': false,
    });

    final terrainIndexes = city['territoryIndexes'];
    for (final index in terrainIndexes) {
      map.zoneColors[kColorModeNation][index] =
          HexColor.fromString(organization['color']);
    }
  }

  void removeCityFromOrganization(dynamic city, dynamic organization) {
    engine.hetu.invoke('removeLocationFromOrganization', positionalArgs: [
      city,
      organization,
    ], namedArgs: {
      'incurIncident': false,
    });

    final terrainIndexes = city['territoryIndexes'];
    for (final index in terrainIndexes) {
      map.zoneColors[kColorModeNation].remove(index);
    }
  }

  void _onTapDownInEditorMode(int button, Vector2 position) {
    if (!GameData.isInteractable) return;

    _focusNode.requestFocus();
    if (button == kPrimaryButton) {
      final tilePosition = map.worldPosition2Tile(position);
      final terrain = map.getTerrain(tilePosition.left, tilePosition.top);
      if (terrain != null) {
        final toolId = context.read<EditorToolState>().selectedId;
        if (toolId != null) {
          _paintTile(toolId, terrain);
        } else if (territoryMode != null) {
          if (terrain.locationId != null) {
            final location = GameData.getLocation(terrain.locationId);
            if (location['category'] == 'city') {
              addCityToOrganization(terrain, territoryMode);
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
              final created =
                  engine.hetu.invoke('createMapComponent', positionalArgs: [
                componentData,
                tile.tilePosition.left,
                tile.tilePosition.top,
              ]);
              map.loadTileMapComponentFromData(created);
            }
        }
    }
  }

  Future<void> _onDragUpdateInEditorMode(Vector2 position) async {
    final tilePosition = map.worldPosition2Tile(position);
    final tile = map.getTerrain(tilePosition.left, tilePosition.top);
    if (tile == null) return;
    final toolId = context.read<EditorToolState>().selectedId;
    if (toolId != null) {
      _paintTile(toolId, tile);
    }
  }

  void _onTapUpInEditorMode(int button, Vector2 position) {
    if (!GameData.isInteractable) return;

    _focusNode.requestFocus();
    final tilePosition = map.worldPosition2Tile(position);
    final selectedTerrain = map.getTerrain(tilePosition.left, tilePosition.top);
    // if (map.trySelectTile(tilePosition.left, tilePosition.top)) {
    //   _setSelectedTerrain(map.selectedTerrain);
    // }
    if (selectedTerrain == null) return;
    cursorState = MouseCursorState.normal;
    if (button == kSecondaryButton) {
      context.read<EditorToolState>().clear();
      territoryMode = null;
      final tileRenderPosition = map.selectedTerrain!.topRight;
      final screenPosition = worldPosition2Screen(tileRenderPosition);
      showFluentMenu(
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
              final organizationId = await GameLogic.selectOrganizationId();
              if (organizationId == null) return;
              final organization = GameData.getOrganization(organizationId);
              territoryMode = organization;
              cursorState = MouseCursorState.click;
            case TerrainPopUpMenuItems.clearTerritory:
              if (selectedTerrain.locationId != null) {
                final location =
                    GameData.getLocation(selectedTerrain.locationId);
                if (location['category'] == 'city' &&
                    selectedTerrain.nationId != null) {
                  final organization =
                      GameData.getOrganization(selectedTerrain.nationId);
                  removeCityFromOrganization(location, organization);
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
                GameDialogContent.show(
                  context,
                  engine.locale('objectIdNonExist', interpolations: [value]),
                );
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
    await _updateCharactersOnWorldMap();

    _updateWorldMapCaptions();

    map.moveCameraToTilePosition(
      map.tileMapWidth ~/ 2,
      map.tileMapHeight ~/ 2,
      animated: false,
    );
  }

  Future<void> _updateCharactersOnWorldMap() async {
    List<dynamic> charactersOnWorldMap = engine.hetu
        .invoke('getCharactersOnWorldMap', positionalArgs: [map.id]).toList();

    final toBeRemoved = [];
    for (final obj in map.components.values) {
      if (obj == map.hero) continue;
      if (!obj.isCharacter) continue;

      final worldPos = obj.data['worldPosition'];
      if (obj.data['worldId'] != map.id || worldPos == null) {
        toBeRemoved.add(obj.id);
      }
      // else {
      //   if (!charactersOnWorldMap.contains(obj.id)) {
      //     toBeRemoved.add(obj.id);
      //   }
      // }
    }

    for (final id in toBeRemoved) {
      map.removeTileMapComponentById(id);
    }

    for (final char in charactersOnWorldMap) {
      if (map.components.values.any((component) {
        return component.id == char['id'];
      })) {
        continue;
      }

      assert(char['worldPosition'] != null);
      int? left = char['worldPosition']['left'];
      int? top = char['worldPosition']['top'];
      if (left == null || top == null) {
        continue;
      }
      final charObj = await map.loadTileMapComponentFromData(
        char,
        isCharacter: true,
        srcSize: kCharacterAnimationSize,
        srcOffset: kTileOffset,
      );
      charObj.tilePosition = TilePosition(left, top);
      map.updateTileInfo(charObj);
    }
  }

  Future<void> _updateNpcsAtHeroPosition() async {
    final npcs = [];
    final worldPos = GameData.hero?['worldPosition'];
    if (worldPos == null ||
        worldPos?['left'] == null ||
        worldPos?['top'] == null) {
      return;
    }

    for (final id in GameData.hero['companions']) {
      final charData = GameData.getCharacter(id);
      npcs.add(charData);
    }

    final otherNpcs = engine.hetu.invoke('getNpcsAtWorldMapPosition',
        positionalArgs: [worldPos['left'], worldPos['top']]);
    npcs.addAll(otherNpcs);
    context.read<NpcListState>().update(npcs);
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

  Future<void> _updateWorldMapCaptions() async {
    final locations = GameData.game['locations'].values;
    for (final location in locations) {
      if (location['worldId'] == GameData.world['id'] &&
          location['terrainIndex'] != null &&
          location['isDiscovered'] == true) {
        final int left = location['worldPosition']['left'];
        final int top = location['worldPosition']['top'];
        _setWorldMapCaption(left, top, location['name'],
            location['category'] == 'city' ? Colors.yellow : Colors.white70);
      }
    }
  }

  Future<void> _updateWorldMapNpc() async {
    await _updateCharactersOnWorldMap();

    await _updateNpcsAtHeroPosition();

    context.read<HeroAndGlobalHistoryState>().update();
  }

  void _tryEnterLocation(dynamic location) async {
    GameData.isInteractable = false;

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
        charComponent = await map.loadTileMapComponentFromData(
          character,
          isCharacter: true,
          srcSize: kCharacterAnimationSize,
          srcOffset: kTileOffset,
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
    charComponent.setDirection(dir, jumpToEnd: true);
    map.updateTileInfo(charComponent);
    if (character == map.hero?.data) {
      _updateHeroTerrain();
    }
  }

  Future<void> _onHeroStep(
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
        GameLogic.updateGame(ticks: timeCost);
      }

      if (staminaCost > 0) {
        final isDying = engine.hetu.invoke('setLife',
            namespace: 'Player',
            positionalArgs: [GameData.hero['life'] - staminaCost]);

        addHintTextOnTile('${engine.locale('stamina')} -${staminaCost.round()}',
            terrain.left, terrain.top,
            color: Colors.red);
        context.read<HeroState>().update();
        if (isDying) {
          map.hero!.isWalkCanceled = true;
          GameLogic.onDying();
          return;
        }
      }
    }

    if (isFinished) {
      final List markedTiles = map.data['markedTiles'] ?? const [];
      if (markedTiles.contains(terrain.index)) {
        markedTiles.remove(terrain.index);
        final overlaySpriteData = terrain.data['overlaySprite'];
        overlaySpriteData.remove('animation');
        await terrain.tryLoadSprite(isOverlay: true);
      }

      engine.hetu.invoke('setCharacterWorldPosition', positionalArgs: [
        GameData.hero,
        map.hero!.tilePosition.left,
        map.hero!.tilePosition.top
      ]);
      await _updateHeroTerrain(tile: terrain, animated: true);
      // 刷新地图上的NPC，这一步只需要在整个移动结束后执行
      await _updateWorldMapNpc();

      if (map.hero!.isWalkCanceled) return;

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
      hero.changedRoute =
          await _calculateRoute(fromTile: lastTerrain, toTile: terrain);
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
      List<int>? calculatedRoute =
          await _calculateRoute(fromTile: heroTerrain, toTile: terrain);

      if (calculatedRoute != null) {
        assert(calculatedRoute.length > 1);
        final result = await engine.hetu
            .invoke('onWorldEvent', positionalArgs: ['onBeforeMove', terrain]);
        if (result == true) {
          return;
        }
        map.componentWalkToTilePositionByRoute(
          map.hero!,
          calculatedRoute,
          onStepCallback: _onHeroStep,
        );
      } else {
        engine.warn(
            '无法将英雄从大地图位置 [${hero.tilePosition}] 移动到 [${terrain.tilePosition}]');
      }
    }
  }

  Future<List<int>?> _calculateRoute({
    TileMapTerrain? fromTile,
    TileMapTerrain? toTile,
    int? fromX,
    int? fromY,
    int? toX,
    int? toY,
    List terrainKinds = kTerrainKindsLand,
  }) async {
    assert(fromTile != null || (fromX != null && fromY != null));
    assert(toTile != null || (toX != null && toY != null));
    fromTile ??= map.getTerrain(fromX!, fromY!);
    toTile ??= map.getTerrain(toX!, toY!);
    List<int>? calculatedRoute = map.calculateRoute(
      fromTile!,
      toTile!,
      terrainKinds: terrainKinds,
    );
    // 如果陆地路线不可达，则尝试计算山地或者水路移动的路线
    if (calculatedRoute == null) {
      final List movableTerrainKinds = engine.hetu.invoke(
        'getCharacterMovableTerrainKinds',
        positionalArgs: [GameData.hero],
      );
      if (movableTerrainKinds.contains(toTile.kind)) {
        calculatedRoute = await _calculateRoute(
          fromTile: fromTile,
          toTile: toTile,
          terrainKinds: movableTerrainKinds,
        );
      } else {
        if (kTerrainKindsWater.contains(toTile.kind)) {
          dialog.pushDialog('hint_ship');
          await dialog.execute();
        } else if (kTerrainKindsMountain.contains(toTile.kind)) {
          dialog.pushDialog('hint_boots');
          await dialog.execute();
        }
      }
    }
    return calculatedRoute;
  }

  Future<void> _onDragUpdateInGameMode(Vector2 position) async {}

  void _onTapDownInGameMode(int button, Vector2 position) {
    if (!GameData.isInteractable) return;
    _focusNode.requestFocus();
    final tilePosition = map.worldPosition2Tile(position);
    map.trySelectTile(tilePosition.left, tilePosition.top);
    if (button == kPrimaryButton) {
      // if (cursorState == MouseCursorState.click) {
      //   cursorState = MouseCursorState.press;
      // }
    } else if (button == kSecondaryButton) {
      // if (map.hero?.isWalking == true) {
      //   map.hero!.isWalkCanceled = true;
      // }
    }
  }

  void _onTapUpInGameMode(int button, Vector2 position) async {
    // if (kDebugMode) {
    //   final screenPosition = worldPosition2Screen(position);
    //   print(
    //       'tapped on map! world position: $position, screen position: $screenPosition');
    // }

    if (!GameData.isInteractable) return;

    _focusNode.requestFocus();

    if (_playerFreezed) return;
    if (map.hero == null) return;

    if (dialog.isOpened) {
      await dialog.execute();
    }

    final tilePosition = map.worldPosition2Tile(position);
    if (button == kPrimaryButton) {
      // if (cursorState == MouseCursorState.press) {
      //   cursorState = MouseCursorState.click;
      // }
      if (tilePosition == map.selectedTerrain?.tilePosition) {
        final terrain = map.selectedTerrain!;
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
      }
    } else if (button == kSecondaryButton) {
      if (tilePosition == map.hero!.tilePosition) {
        final menuPosition =
            worldPosition2Screen(map.selectedTerrain!.topRight);
        showFluentMenu(
          position: menuPosition.toOffset(),
          items: {
            engine.locale('terrainInformation'):
                WorldMapPopUpMenuItems.terrainInformation,
            engine.locale('build'): {
              engine.locale('farmland'): WorldMapPopUpMenuItems.buildFarmLand,
              engine.locale('fishery'): WorldMapPopUpMenuItems.buildFishery,
              engine.locale('timberland'):
                  WorldMapPopUpMenuItems.buildTimberLand,
              engine.locale('mine'): WorldMapPopUpMenuItems.buildMine,
              engine.locale('huntingground'):
                  WorldMapPopUpMenuItems.buildHuntingGround,
            },
            engine.locale('warMode'): WorldMapPopUpMenuItems.warMode,
          },
          onSelectedItem: (item) {
            switch (item) {
              case WorldMapPopUpMenuItems.terrainInformation:
              case WorldMapPopUpMenuItems.buildFarmLand:
              case WorldMapPopUpMenuItems.buildFishery:
              case WorldMapPopUpMenuItems.buildTimberLand:
              case WorldMapPopUpMenuItems.buildMine:
              case WorldMapPopUpMenuItems.buildHuntingGround:
              case WorldMapPopUpMenuItems.warMode:
            }
          },
        );
      }
    }
  }

  Future<void> _onAfterLoadedInGameMode() async {
    _focusNode.requestFocus();
    final bool isNewGame = GameData.game['isNewGame'] ?? false;
    if (isNewGame) {
      // GameLogic.updateGame(timeflow: false);
      if (GameData.hero == null) {
        final Iterable characters = GameData.game['characters'].values;
        final List availableCharacters = characters.where((character) {
          final age = engine.hetu
              .invoke('getCharacterAge', positionalArgs: [character]);
          if (age > kMaxHeroAge) {
            return false;
          }
          final int rank = character['rank'];
          if (rank > 0) {
            return false;
          }
          final organizationId = character['organizationId'];
          if (organizationId != null) {
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
            showCloseButton: false,
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
    } else {
      // if (GameData.hero['worldId'] == map.id) {
      //   _characterSetToWorldPosition(
      //     GameData.hero,
      //     GameData.hero['worldPosition']['left'],
      //     GameData.hero['worldPosition']['top'],
      //     direction: 'south',
      //   );
      // }
    }

    assert(GameData.hero != null);
    await map.loadHeroFromData(
      GameData.hero,
      srcSize: kCharacterAnimationSize,
      srcOffset: kTileOffset,
    );
    map.moveCameraToHero(animated: false);

    _updateWorldMapCaptions();

    context.read<HeroInfoVisibilityState>().setVisible(
        isNewGame ? (map.data['useCustomLogic'] != true ? true : false) : true);
    context.read<HeroAndGlobalHistoryState>().update();
    context.read<HeroJournalUpdate>().update();

    if (isMainWorld) {
      for (var i = 0; i < kMaxCloudsCount ~/ 2; ++i) {
        _addCloud();
      }
    }

    if (isNewGame) {
      await engine.hetu.invoke('onNewGame');
    }

    await _enterScene(updateHeroTerrain: true);
  }

  Future<void> _enterScene({bool updateHeroTerrain = true}) async {
    await engine.hetu.invoke('onWorldEvent', positionalArgs: ['onEnterMap']);

    await _updateWorldMapNpc();

    if (updateHeroTerrain) {
      await _updateHeroTerrain();

      if (map.data['useCustomLogic'] != true) {
        map.lightUpAroundTile(map.hero!.tilePosition,
            size: GameData.hero['stats']['lightRadius']);
      }
    }
  }

  @override
  FutureOr<void> onStart([dynamic arguments = const {}]) async {
    super.onStart(arguments);

    GameData.isInteractable = true;

    GameData.world = worldData;

    engine.hetu.invoke('setCurrentWorld', positionalArgs: [worldData['id']]);

    if (!isLoaded || !map.isLoaded) return;

    _enterScene();
  }

  @override
  void onMount() {
    super.onMount();
    cursorState = MouseCursorState.normal;
    context.read<GameTimestampState>().update();
    context.read<NpcListState>().update();
    context.read<HeroJournalUpdate>().update();
    context.read<HeroPositionState>().updateLocation();
    context.read<HeroPositionState>().updateDungeon();
  }

  // TODO: 自动移动屏幕
  void _onMouseEnterScreenEdge(OrthogonalDirection direction) {
    context.read<HoverContentState>().hide();
  }

  void _onMouseEnterTile(TileMapTerrain? tile) {
    if (!GameData.isInteractable) return;

    bool clickable = false;
    if (tile != null && (tile.isLighted || !map.showFogOfWar)) {
      final hoverContent = StringBuffer();
      if (tile.zoneId != null) {
        final zone = GameData.world['zones'][tile.zoneId];
        hoverContent.write('${zone['name']}');
      }
      hoverContent.writeln(' ${engine.locale(tile.kind)}'
          '${engine.config.debugMode ? ' <grey>#${tile.index}</>' : ''}'
          ' [${tile.left}, ${tile.top}]');
      if (tile.nationId != null) {
        final organization = GameData.getOrganization(tile.nationId);
        hoverContent.write(organization['name']);
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
      //       '<grey>renderPosition: (${renderPosition.x.toStringAsFixed(1)}, ${renderPosition.y.toStringAsFixed(1)})</>');
      //   hoverContent.writeln(
      //       '<grey>screenPosition: (${screenPosition.x.toStringAsFixed(1)}, ${screenPosition.y.toStringAsFixed(1)})</>');
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
      } else {
        context.read<HoverContentState>().hide();
      }
    } else {
      context.read<HoverContentState>().hide();
    }

    if (clickable) {
      cursorState = MouseCursorState.click;
    } else {
      cursorState = MouseCursorState.normal;
    }
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
          engine.debug('KeyDownEvent: ${event.logicalKey.debugName}');
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
                context.read<EditorToolState>().clear();

                if (territoryMode != null) {
                  territoryMode = null;
                  cursorState = MouseCursorState.normal;
                }
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
          engine.debug('KeyRepeatEvent: ${event.logicalKey.debugName}');
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
              showActiveJournal: true,
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
              onUpdateCharacters: _updateCharactersOnWorldMap,
              onUpdateLocations: _updateWorldMapCaptions,
              onCreatedOrganization: (organization, location) {
                final territoryIndexes = location['territoryIndexes'];
                for (final index in territoryIndexes) {
                  map.zoneColors[kColorModeNation][index] =
                      HexColor.fromString(organization['color']);
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
