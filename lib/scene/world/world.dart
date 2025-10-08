import 'dart:math' as math;
import 'dart:async';

import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
// import 'package:samsara/pointer_detector.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
import 'package:hetu_script/values.dart';
import 'package:flame/flame.dart';
import 'package:provider/provider.dart';
import 'package:samsara/effect/camera_shake.dart';
// import 'package:flame/game.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import 'particles/cloud.dart';
import 'particles/rubble.dart';
import '../common.dart';
import '../../game/ui.dart';
// import 'animation/flying_sword.dart';
import '../../game/data.dart';
import '../../state/states.dart';
import '../game_dialog/game_dialog_content.dart';
import '../../widgets/ui_overlay.dart';
// import '../../widgets/quest_panel.dart';
import '../../widgets/dialog/input_string.dart';
import '../../widgets/entity_listview.dart';
import '../../widgets/ui/menu_builder.dart';
import '../mainmenu/create_blank_map.dart';
import 'widgets/entity_list.dart';
import 'widgets/expand_world_dialog.dart';
import 'widgets/tile_detail.dart';
// import 'widgets/tile_info.dart';
import 'widgets/toolbox.dart';
import '../../widgets/dialog/confirm.dart';
import '../../game/logic/logic.dart';
import 'components/banner.dart';
import '../../game/common.dart';
import '../../widgets/location_panel.dart';

enum WorldMapPopUpMenuItems {
  moveTo,
  terrainInformation,
  buildFarmLand,
  buildFishery,
  buildTimberLand,
  buildMine,
  buildHuntingGround,
  warMode,
}

enum WorldMapDropMenuItems {
  save,
  saveAs,
  info,
  viewNone,
  viewZones,
  viewOrganizations,
  console,
  exit
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
  viewZones,
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

class WorldMapScene extends Scene {
  static final random = math.Random();

  WorldMapScene({
    required super.context,
    required this.worldData,
    required this.isEditorMode,
    this.backgroundSpriteId,
    super.bgmFile,
  })  : assert(GameData.spriteSheets
            .containsKey('tilemap/fantasyhextiles_v3_borderless.png')),
        map = TileMap(
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

  // final Map<TilePosition, String> _hoveringTileInfo = {};

  Sprite? backgroundSprite;

  final String? backgroundSpriteId;

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

  final List<dynamic> _npcsAtHeroPosition = [];

  Future<void> _updateHeroTerrain(
      {TileMapTerrain? tile, bool animated = false}) async {
    if (map.hero == null) return;

    final terrain = tile ?? map.getTerrain(map.hero!.left, map.hero!.top)!;

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

    await map.moveCameraToTilePosition(terrain.left, terrain.top,
        animated: animated);
  }

  TileMapTerrain? _selectedTerrain;
  dynamic _selectedZone;
  dynamic _selectedNation;
  dynamic _selectedLocation;

  void _setSelectedTerrain(TileMapTerrain? terrain) {
    _selectedTerrain = terrain;
    if (_selectedTerrain == null) return;

    final zoneId = _selectedTerrain!.zoneId;
    if (zoneId != null) {
      _selectedZone =
          engine.hetu.invoke('getZoneById', positionalArgs: [zoneId]);
    } else {
      _selectedZone = null;
    }

    final nationId = _selectedTerrain!.nationId;
    if (nationId != null) {
      _selectedNation =
          engine.hetu.invoke('getOrganizationById', positionalArgs: [nationId]);
    } else {
      _selectedNation = null;
    }

    final String? locationId = _selectedTerrain!.locationId;
    if (locationId != null) {
      _selectedLocation = GameData.getLocation(locationId);
    } else {
      _selectedLocation = null;
    }

    context.read<SelectedPositionState>().update(
          currentZoneData: _selectedZone,
          currentNationData: _selectedNation,
          currentLocationData: _selectedLocation,
          currentTerrainObject: _selectedTerrain,
        );
  }

  // bool _isInteracting = false;

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);

    if (!isEditorMode && isMainWorld) {
      final r = random.nextDouble();
      if (r < 0.01) {
        _addCloud();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    backgroundSprite?.render(canvas, size: size);

    super.render(canvas);

    if (engine.config.debugMode || engine.config.showFps) {
      drawScreenText(
        canvas,
        'FPS: ${fps.fps.toStringAsFixed(0)}',
        config: ScreenTextConfig(
          textStyle: const TextStyle(fontSize: 20),
          size: GameUI.size,
          anchor: Anchor.topCenter,
          padding: const EdgeInsets.only(top: 40),
        ),
      );
    }
  }

  void loadZoneColors() {
    final colors = engine.hetu.invoke('getCurrentWorldZoneColors');
    engine.debug('刷新地图 ${map.id} 上色信息');
    engine.loadTileMapZoneColors(map, colors);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    camera.zoom = 2.0;

    if (backgroundSpriteId != null) {
      backgroundSprite = Sprite(await Flame.images.load(backgroundSpriteId!));
    }

    map.onAfterLoaded =
        isEditorMode ? _onMapLoadedInEditorMode : _onMapLoadedInGameMode;

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
        isEditorMode ? _onMapTapDownInEditorMode : _onMapTapDownInGameMode;
    map.onTapUp =
        isEditorMode ? _onMapTapUpInEditorMode : _onMapTapUpInGameMode;
    map.onDragStart = (int button, Vector2 position) {
      if (button == kPrimaryButton) {
        isEditorMode
            ? _onMapDragUpdateInEditorMode(position)
            : _onMapDragUpdateInGameMode(position);
      }
      return null;
    };
    map.onDragUpdate = (int button, Vector2 position, Vector2 delta) {
      if (button == kPrimaryButton) {
        isEditorMode
            ? _onMapDragUpdateInEditorMode(position)
            : _onMapDragUpdateInGameMode(position);
      } else if (button == kSecondaryButton) {
        camera.moveBy(-camera.localToGlobal(delta) / camera.zoom);
      }
    };
    map.onDragEnd = (int button, Vector2 offset) {
      engine.setCursor(Cursors.normal);
    };

    world.add(map);

    if (!isEditorMode && isMainWorld) {
      for (var i = 0; i < kMaxCloudsCount ~/ 2; ++i) {
        _addCloud();
      }
    }

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

    engine.hetu.interpreter.bindExternalFunction(
        'World::setCharacterToPosition', ({positionalArgs, namedArgs}) async {
      final worldId = namedArgs['worldId'];
      if (worldId == null || worldId == map.id) {
        late TileMapComponent charComponent;
        final charId = positionalArgs[0];
        if (charId == map.hero?.id) {
          charComponent = map.hero!;
          if (!map.components.containsKey(charId)) {
            map.add(charComponent);
            map.components[charId] = charComponent;
          }
        } else {
          if (map.components.containsKey(charId)) {
            charComponent = map.components[charId]!;
          } else {
            // final charData = GameData.getCharacter(charId);
            final charData = positionalArgs.first;
            charComponent = await map.loadTileMapComponentFromData(
              charData,
              spriteSrcSize: kWorldMapCharacterSpriteSrcSize,
              isCharacter: true,
            );
          }
        }
        charComponent.tilePosition =
            TilePosition(positionalArgs[1], positionalArgs[2]);
        final direction = namedArgs['direction'];
        if (direction != null) {
          final dir = OrthogonalDirection.values
              .singleWhere((element) => element.name == direction);
          charComponent.setDirection(dir, jumpToEnd: true);
        }
        map.updateTileInfo(charComponent);
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::removeCharacter', (
        {positionalArgs, namedArgs}) {
      map.components.remove(positionalArgs.first)?.removeFromParent();
    });

    engine.hetu.interpreter.bindExternalFunction('World::characterWalkTo', (
        {positionalArgs, namedArgs}) {
      final character = map.components[positionalArgs[0]];
      if (character == null) {
        engine.warn('大地图对象 id [${positionalArgs[0]}] 不存在');
        return null;
      }
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

      final route = _calculateRoute(
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

    engine.hetu.interpreter.bindExternalFunction('World::updateNpcsAtLocation',
        ({positionalArgs, namedArgs}) => _updateNpcsAtLocation(),
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

    engine.hetu.interpreter.bindExternalFunction(
        'World::enterLocation',
        ({positionalArgs, namedArgs}) =>
            GameLogic.tryEnterLocation(positionalArgs.first),
        override: true);

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
  void onMount() async {
    super.onMount();

    context.read<HeroPositionState>().updateLocation(null);

    GameData.world = worldData;

    // final worldPos = GameData.heroData['worldPosition'];
    // if (worldPos != null) {
    //   map.lightUpAroundTile(
    //     TilePosition(worldPos['left'], worldPos['top']),
    //     size: GameData.heroData['stats']['lightRadius'],
    //   );
    // }
  }

  @override
  void onEnd() {
    super.onEnd();

    map.saveComponentsFrameData();
  }

  void _addCloud() {
    final cloud = ParticleCloud();
    cloud.position = map.getRandomTerrainPosition();
    world.add(cloud);
  }

  /// start & end are flame game canvas world position.
  // void _useMapSkillFlyingSword(Vector2 start, Vector2 end) {
  //   final swordAnim = FlyingSword(start: start, end: end);
  //   map.add(swordAnim);
  // }

  void addTerrainToOrganization(TileMapTerrain terrain, dynamic organization) {
    if (terrain.nationId == organization['id']) return;
    engine.hetu.invoke('addTerrainToOrganization', positionalArgs: [
      terrain.data,
      organization,
    ], namedArgs: {
      'incurIncident': false,
    });
    terrain.nationId = organization['id'];
    map.zoneColors[1][terrain.index] =
        HexColor.fromString(organization['color']);
  }

  void removeTerrainFromOrganization(TileMapTerrain terrain) {
    engine.hetu.invoke('removeTerrainFromOrganization', positionalArgs: [
      map.selectedTerrain!.data
    ], namedArgs: {
      'incurIncident': false,
    });
    map.zoneColors[1].remove(map.selectedTerrain!.index);
  }

  void _onMapTapDownInEditorMode(int button, Vector2 position) {
    _focusNode.requestFocus();
    if (button == kPrimaryButton) {
      final tilePosition = map.worldPosition2Tile(position);
      final terrain = map.getTerrain(tilePosition.left, tilePosition.top);
      if (terrain != null) {
        final toolId = context.read<EditorToolState>().selectedId;
        if (toolId != null) {
          _paintTile(toolId, terrain);
        } else if (territoryMode != null) {
          addTerrainToOrganization(terrain, territoryMode);
        }
      }
    } else if (button == kSecondaryButton) {
      engine.setCursor(Cursors.drag);
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

  Future<void> _onMapDragUpdateInEditorMode(Vector2 position) async {
    final tilePosition = map.worldPosition2Tile(position);
    final tile = map.getTerrain(tilePosition.left, tilePosition.top);
    if (tile == null) return;
    final toolId = context.read<EditorToolState>().selectedId;
    if (toolId != null) {
      _paintTile(toolId, tile);
    } else if (territoryMode != null) {
      addTerrainToOrganization(tile, territoryMode);
    }
  }

  void _onMapTapUpInEditorMode(int button, Vector2 position) {
    _focusNode.requestFocus();
    final tilePosition = map.worldPosition2Tile(position);
    if (map.trySelectTile(tilePosition.left, tilePosition.top)) {
      _setSelectedTerrain(map.selectedTerrain);
    }
    if (_selectedTerrain == null) return;
    if (button == kSecondaryButton) {
      engine.setCursor(Cursors.normal);
      context.read<EditorToolState>().clear();
      territoryMode = null;
      final tileRenderPosition = map.selectedTerrain!.renderBottomRight;
      final screenPosition = map.worldPosition2Screen(tileRenderPosition);
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
              engine.setCursor(Cursors.click);
            case TerrainPopUpMenuItems.clearTerritory:
              removeTerrainFromOrganization(map.selectedTerrain!.data);
            case TerrainPopUpMenuItems.bindLocation:
              final locationId = await GameLogic.selectLocationId();
              if (locationId == null) return;
              _selectedTerrain!.locationId = locationId;
              final location = GameData.getLocation(locationId);
              _selectedTerrain!.caption = location['name'];
            case TerrainPopUpMenuItems.clearLocation:
              _selectedTerrain!.locationId = null;
              _selectedTerrain!.caption = null;
            case TerrainPopUpMenuItems.bindObject:
              final value = await showDialog(
                context: context,
                builder: (context) => const InputStringDialog(),
              );
              if (value == null) return;
              final hasObject =
                  engine.hetu.invoke('hasObject', positionalArgs: [value]);
              if (hasObject) {
                _selectedTerrain!.objectId = value;
                _selectedTerrain!.caption = value;
              } else {
                GameDialogContent.show(
                  context,
                  engine.locale('objectIdNonExist', interpolations: [value]),
                );
              }
            case TerrainPopUpMenuItems.clearObject:
              _selectedTerrain!.objectId = null;
              _selectedTerrain!.caption = null;
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
              _selectedTerrain!.kind = kTerrainKindVoid;
            case TerrainPopUpMenuItems.plain:
              _selectedTerrain!.kind = kTerrainKindPlain;
            case TerrainPopUpMenuItems.mountain:
              _selectedTerrain!.kind = kTerrainKindMountain;
            case TerrainPopUpMenuItems.forest:
              _selectedTerrain!.kind = kTerrainKindForest;
            case TerrainPopUpMenuItems.shore:
              _selectedTerrain!.kind = kTerrainKindShore;
            case TerrainPopUpMenuItems.shelf:
              _selectedTerrain!.kind = kTerrainKindShelf;
            case TerrainPopUpMenuItems.lake:
              _selectedTerrain!.kind = kTerrainKindLake;
            case TerrainPopUpMenuItems.sea:
              _selectedTerrain!.kind = kTerrainKindSea;
            case TerrainPopUpMenuItems.river:
              _selectedTerrain!.kind = kTerrainKindRiver;
            case TerrainPopUpMenuItems.road:
              _selectedTerrain!.kind = kTerrainKindRoad;
            case TerrainPopUpMenuItems.city:
              _selectedTerrain!.kind = kTerrainKindCity;
            case TerrainPopUpMenuItems.clearTerrainSprite:
              _selectedTerrain!.clearSprite();
              _selectedTerrain!.kind = kTerrainKindVoid;
            case TerrainPopUpMenuItems.clearTerrainAnimation:
              _selectedTerrain!.clearAnimation();
            case TerrainPopUpMenuItems.clearTerrainOverlaySprite:
              _selectedTerrain!.clearOverlaySprite();
            case TerrainPopUpMenuItems.clearTerrainOverlayAnimation:
              _selectedTerrain!.clearOverlayAnimation();
          }
          _setSelectedTerrain(map.selectedTerrain);
        },
      );
    }
  }

  Future<void> _onMapLoadedInEditorMode() async {
    _focusNode.requestFocus();
    await _updateCharactersOnWorldMap();

    _updateWorldMapCaptions();

    map.moveCameraToTilePosition(
      map.tileMapWidth ~/ 2,
      map.tileMapHeight ~/ 2,
      animated: false,
    );

    engine.setLoading(false);
  }

  Future<void> _updateCharactersOnWorldMap() async {
    List<dynamic> charactersOnWorldMap = engine.hetu
        .invoke('getCharactersOnWorldMap', positionalArgs: [map.id]).toList();

    final toBeRemoved = [];
    for (final obj in map.components.values) {
      if (!obj.isCharacter) continue;

      final worldPos = obj.data['worldPosition'];
      if (obj.data['worldId'] != map.id ||
          worldPos['left'] == null ||
          worldPos['top'] == null) {
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
      final charObj = await map.loadTileMapComponentFromData(char,
          spriteSrcSize: kWorldMapCharacterSpriteSrcSize, isCharacter: true);
      charObj.tilePosition = TilePosition(left, top);
      map.updateTileInfo(charObj);
    }
  }

  Future<void> _updateNpcsAtHeroPosition() async {
    _npcsAtHeroPosition.clear();
    final worldPos = GameData.hero?['worldPosition'];
    if (worldPos == null ||
        worldPos?['left'] == null ||
        worldPos?['top'] == null) {
      return;
    }

    for (final id in GameData.hero['companions']) {
      final charData = GameData.getCharacter(id);
      _npcsAtHeroPosition.add(charData);
    }

    final otherNpcs = engine.hetu.invoke('getNpcsAtWorldMapPosition',
        positionalArgs: [worldPos['left'], worldPos['top']]);
    _npcsAtHeroPosition.addAll(otherNpcs);
    context.read<NpcListState>().update(_npcsAtHeroPosition);
  }

  Future<void> _updateNpcsAtLocation() async {
    _npcsAtHeroPosition.clear();

    for (final id in GameData.hero['companions']) {
      final charData = GameData.getCharacter(id);
      _npcsAtHeroPosition.add(charData);
    }

    final otherNpcs =
        engine.hetu.invoke('getNpcsAtLocationId', positionalArgs: [
      GameData.hero?['locationId'],
    ]);
    _npcsAtHeroPosition.addAll(otherNpcs);

    context.read<NpcListState>().update(_npcsAtHeroPosition);
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
            location['category'] == 'city' ? Colors.white : Colors.yellow);
      }
    }
  }

  Future<void> _updateWorldMapNpc() async {
    await _updateCharactersOnWorldMap();

    await _updateNpcsAtHeroPosition();

    context.read<HeroAndGlobalHistoryState>().update();
  }

  void _tryEnterLocation(dynamic location) async {
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

  void _heroMoveTo(TileMapTerrain terrain) async {
    if (!terrain.isLighted && map.showFogOfWar) return;
    final hero = map.hero!;
    if (hero.isWalking) return;

    final heroTerrain = map.getTerrain(hero.left, hero.top);
    final neighbors = map.getNeighborTiles(heroTerrain!);
    if (terrain.isNonEnterable &&
        neighbors.containsValue(terrain) &&
        terrain.objectId != null) {
      GameLogic.tryInteractObject(terrain.objectId!, terrain.data);
      return;
    } else {
      final movableTerrainKinds = await engine.hetu
          .invoke('onBeforeMove', positionalArgs: [terrain.data]);
      if (movableTerrainKinds == null || movableTerrainKinds.isEmpty) {
        return;
      }
      final calculatedRoute = _calculateRoute(
        fromTile: heroTerrain,
        toTile: terrain,
        terrainKinds: movableTerrainKinds,
      );
      if (calculatedRoute != null) {
        assert(calculatedRoute.length > 1);
        final route = List<int>.from(calculatedRoute);
        map.componentWalkToTilePositionByRoute(
          map.hero!,
          route,
          onStepCallback: (terrain, next, isFinished) async {
            if (next != null) {
              if (next.objectId != null) {
                // 如果下一个格子有物体，且该物体 blockMove 为 true
                // 意味着该物体会阻挡移动
                final objectsData =
                    engine.hetu.fetch('objects', namespace: 'world');
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
              double cost = 0;
              if (kTerrainKindsWater.contains(terrain.kind)) {
                cost = GameLogic.getMoveCostOnWater();
              } else if (kTerrainKindsMountain.contains(terrain.kind)) {
                cost = GameLogic.getMoveCostOnHill();
              }

              if (cost > 0) {
                final isTribulation = engine.hetu.invoke('setLife',
                    namespace: 'Player',
                    positionalArgs: [GameData.hero['life'] - cost]);
                context.read<HeroState>().update();
                if (isTribulation) {
                  GameLogic.onDying();
                }
              }

              /// 实际移动一格后的回调
              map.lightUpAroundTile(
                terrain.tilePosition,
                size: map.hero!.data['stats']['lightRadius'],
                // excludeTerrainKinds: kExcludeTerrainKindsOnLighting,
              );
              final result = await engine.hetu.invoke('onWorldEvent',
                  positionalArgs: ['onAfterMove', terrain.data]);
              map.hero!.isWalkCanceled = result ?? false;
              // TODO: 某些情况下，让英雄返回上一格
              // map.objectWalkToPreviousTile(map.hero!);
              if (isMainWorld) {
                GameLogic.updateGame();
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
                hero.tilePosition.left,
                hero.tilePosition.top
              ]);
              await _updateHeroTerrain(tile: terrain, animated: true);
              // 刷新地图上的NPC，这一步只需要在整个移动结束后执行
              await _updateWorldMapNpc();

              if (next != null && next.objectId != null) {
                GameLogic.tryInteractObject(next.objectId!, next.data);
              } else {
                if (terrain.objectId != null) {
                  GameLogic.tryInteractObject(terrain.objectId!, terrain.data);
                } else if (terrain.locationId != null) {
                  final location = GameData.getLocation(terrain.locationId);
                  _tryEnterLocation(location);
                }
              }

              // 如果英雄所在格子只有一个npc，则默认直接和该npc互动
              // if (_npcsInHeroPosition.length == 1) {
              //   final npcId = _npcsInHeroPosition.first['id'];
              //   engine.hetu.invoke('onInteractCharacter', positionalArgs: [npcId]);
              // }
            }
          },
        );
      } else {
        engine.warn(
            '无法将英雄从大地图位置 [${hero.tilePosition}] 移动到 [${terrain.tilePosition}]');
      }
    }
  }

  List? _calculateRoute({
    TileMapTerrain? fromTile,
    TileMapTerrain? toTile,
    int? fromX,
    int? fromY,
    int? toX,
    int? toY,
    List terrainKinds = const [],
  }) {
    assert(fromTile != null || (fromX != null && fromY != null));
    assert(toTile != null || (toX != null && toY != null));
    fromTile ??= map.getTerrain(fromX!, fromY!);
    toTile ??= map.getTerrain(toX!, toY!);
    List? calculatedRoute = map.calculateRoute(
      fromTile!,
      toTile!,
      terrainKinds: terrainKinds,
    );
    return calculatedRoute;
  }

  Future<void> _onMapDragUpdateInGameMode(Vector2 position) async {}

  void _onMapTapDownInGameMode(int button, Vector2 position) {
    _focusNode.requestFocus();
    final tilePosition = map.worldPosition2Tile(position);
    map.trySelectTile(tilePosition.left, tilePosition.top);
    if (button == kPrimaryButton) {
      if (engine.cursor == Cursors.click) {
        engine.setCursor(Cursors.press);
      }
    } else if (button == kSecondaryButton) {
      engine.setCursor(Cursors.drag);
    }
  }

  void _onMapTapUpInGameMode(int button, Vector2 position) async {
    context.read<HoverContentState>().hide();

    _focusNode.requestFocus();

    if (_playerFreezed) return;
    if (map.hero == null) return;

    final isGameDialogOpened = context.read<GameDialog>().isOpened;
    if (isGameDialogOpened) return;

    final tilePosition = map.worldPosition2Tile(position);
    if (button == kPrimaryButton) {
      if (engine.cursor == Cursors.press) {
        engine.setCursor(Cursors.click);
      }
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
      engine.setCursor(Cursors.normal);
      final tileRenderPosition = map.selectedTerrain!.renderBottomRight;
      final screenPosition = map.worldPosition2Screen(tileRenderPosition);
      showFluentMenu(
          position: screenPosition.toOffset(),
          items: {
            engine.locale('moveTo'): WorldMapPopUpMenuItems.moveTo,
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
              case WorldMapPopUpMenuItems.moveTo:
              case WorldMapPopUpMenuItems.terrainInformation:
              case WorldMapPopUpMenuItems.buildFarmLand:
              case WorldMapPopUpMenuItems.buildFishery:
              case WorldMapPopUpMenuItems.buildTimberLand:
              case WorldMapPopUpMenuItems.buildMine:
              case WorldMapPopUpMenuItems.buildHuntingGround:
              case WorldMapPopUpMenuItems.warMode:
            }
          });
    }
  }

  Future<void> _onMapLoadedInGameMode() async {
    _focusNode.requestFocus();
    final bool isNewGame = GameData.game['isNewGame'] ?? false;
    if (isNewGame) {
      // GameLogic.updateGame(timeflow: false);

      if (GameData.hero == null) {
        final Iterable characters = GameData.game['characters'].values;
        final Iterable filteredCharacters = characters.where((character) {
          final age = engine.hetu
              .invoke('getCharacterAge', positionalArgs: [character]);
          if (age > kMaxHeroAge) {
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
        });
        assert(filteredCharacters.isNotEmpty,
            'No available character to be selected as hero!');
        final key = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => EntityListView(
            showCloseButton: false,
            mode: EntityListViewMode.selectCharacter,
            characters: filteredCharacters,
          ),
        );
        engine.hetu.invoke('setHero', positionalArgs: [key]);
        engine.hetu.invoke('randomizeHeroWorldPosition');
        GameData.hero = engine.hetu.fetch('hero');
        final heroHomeLocation =
            GameData.getLocation(GameData.hero['homeLocationId']);
        await engine.hetu.invoke('discoverLocation', positionalArgs: [
          heroHomeLocation,
        ], namedArgs: {
          'updateWorldMap': true,
        });
      }
    }

    assert(GameData.hero != null);
    await map.loadHeroFromData(GameData.hero, kWorldMapCharacterSpriteSrcSize);

    await _updateHeroTerrain();

    _updateWorldMapCaptions();

    if (map.data['useCustomLogic'] != true) {
      map.lightUpAroundTile(map.hero!.tilePosition,
          size: GameData.hero['stats']['lightRadius']);

      GameData.hero['locationId'] = null;
    }

    context.read<HeroState>().update();
    context.read<HeroInfoVisibilityState>().setVisible(
        isNewGame ? (map.data['useCustomLogic'] != true ? true : false) : true);
    context.read<GameTimestampState>().update();
    context.read<HeroAndGlobalHistoryState>().update();

    engine.setLoading(false);

    if (isNewGame) {
      await engine.hetu.invoke('onNewGame');
    }

    await _enterScene(updateHeroTerrain: false);
  }

  Future<void> _enterScene({bool updateHeroTerrain = true}) async {
    await _updateWorldMapNpc();
    if (updateHeroTerrain) {
      await _updateHeroTerrain();
    }

    await engine.hetu.invoke('onWorldEvent', positionalArgs: ['onEnterMap']);
  }

  @override
  FutureOr<void> onStart([dynamic arguments = const {}]) async {
    super.onStart(arguments);

    if (!isLoaded || !map.isLoaded) return;

    _enterScene();
  }

  void _onMouseEnterTile(TileMapTerrain? tile) {
    if (isEditorMode) return;

    if (tile != null &&
        tile.objectId != null &&
        (tile.isLighted || !map.showFogOfWar)) {
      engine.setCursor(Cursors.click);
      // context.read<CursorState>().set(Cursors.click);
      final objectsData = engine.hetu.fetch('objects', namespace: 'world');
      final objectData = objectsData[tile.objectId!];
      assert(objectData != null, 'objectId: ${tile.objectId} not found!');
      String? hoverContent = objectData?['hoverContent'];

      final screenPosition = map.worldPosition2Screen(tile.renderPosition);
      if (hoverContent != null) {
        if (engine.config.debugMode) {
          hoverContent += '\n${objectData['id']}';
        }
        context.read<HoverContentState>().show(
              hoverContent,
              Rect.fromLTWH(
                screenPosition.x + map.tileOffset.x * camera.zoom,
                screenPosition.y + map.tileOffset.y * camera.zoom,
                tile.renderSize.x * camera.zoom,
                tile.renderSize.y * camera.zoom,
              ),
              direction: HoverContentDirection.topCenter,
            );
      }
    } else {
      engine.setCursor(Cursors.normal);
      // context.read<CursorState>().set('normal');
      context.read<HoverContentState>().hide();
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
    final screenPosition = map.worldPosition2Screen(worldPosition);

    super.addHintText(
      text,
      position: screenPosition,
      horizontalVariation: 10.0,
      verticalVariation: 10.0,
      offsetY: 20.0,
      duration: duration,
      textStyle: TextStyle(
        color: color ?? Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        fontFamily: GameUI.fontFamily,
      ),
    );
  }

  Future<void> promptTextBanner(String text) async {
    final prompt = PromptTextBanner(
      text: text,
      backgroundColor: GameUI.backgroundColor3,
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
    return Stack(
      children: [
        KeyboardListener(
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
                      engine.setCursor(Cursors.normal);
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
                  action: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(color: GameUI.foregroundColor),
                    ),
                    child: fluent.FlyoutTarget(
                      controller: menuController,
                      child: IconButton(
                        icon: const Icon(Icons.menu_open, size: 20.0),
                        mouseCursor: MouseCursor.defer,
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          showFluentMenu<WorldMapDropMenuItems>(
                            controller: menuController,
                            items: {
                              engine.locale('save'): WorldMapDropMenuItems.save,
                              engine.locale('saveAs'):
                                  WorldMapDropMenuItems.saveAs,
                              engine.locale('view'): {
                                engine.locale('none'):
                                    WorldMapDropMenuItems.viewNone,
                                engine.locale('zone'):
                                    WorldMapDropMenuItems.viewZones,
                                engine.locale('organization'):
                                    WorldMapDropMenuItems.viewOrganizations,
                              },
                              '___1': null,
                              engine.locale('info'): WorldMapDropMenuItems.info,
                              '___2': null,
                              engine.locale('console'):
                                  WorldMapDropMenuItems.console,
                              '___3': null,
                              engine.locale('exit'): WorldMapDropMenuItems.exit,
                            },
                            onSelectedItem: (WorldMapDropMenuItems item) async {
                              switch (item) {
                                case WorldMapDropMenuItems.save:
                                  map.saveComponentsFrameData();
                                  String worldId = GameData.world['id'];
                                  String? saveName = engine.hetu
                                      .fetch('saveName', namespace: 'game');
                                  final saveInfo = await context
                                      .read<GameSavesState>()
                                      .saveGame(worldId, saveName);
                                  if (saveInfo != null) {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('savedSuccessfully',
                                          interpolations: [saveInfo.savePath]),
                                    );
                                  } else {
                                    GameDialogContent.show(
                                        context, engine.locale('saveFailed'));
                                  }
                                case WorldMapDropMenuItems.saveAs:
                                  map.saveComponentsFrameData();
                                  final saveName = await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return InputStringDialog(
                                        title: engine.locale('inputName'),
                                      );
                                    },
                                  );
                                  if (saveName == null) return;
                                  engine.hetu.assign('saveName', saveName,
                                      namespace: 'game');
                                  String worldId = GameData.world['id'];
                                  final saveInfo = await context
                                      .read<GameSavesState>()
                                      .saveGame(worldId, saveName);
                                  if (saveInfo != null) {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('savedSuccessfully',
                                          interpolations: [saveInfo.savePath]),
                                    );
                                  } else {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('saveFailed'),
                                    );
                                  }
                                case WorldMapDropMenuItems.info:
                                  showDialog(
                                      context: context,
                                      builder: (context) =>
                                          const EntityListView());
                                case WorldMapDropMenuItems.viewNone:
                                  map.colorMode = kColorModeNone;
                                case WorldMapDropMenuItems.viewZones:
                                  map.colorMode = kColorModeZone;
                                case WorldMapDropMenuItems.viewOrganizations:
                                  map.colorMode = kColorModeOrganization;
                                case WorldMapDropMenuItems.console:
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Console(
                                      engine: engine,
                                      margin: const EdgeInsets.all(50.0),
                                      backgroundColor: GameUI.backgroundColor2,
                                    ),
                                  );
                                case WorldMapDropMenuItems.exit:
                                  context.read<SelectedPositionState>().clear();
                                  context.read<HeroPositionState>().clear();
                                  engine.clearAllCachedScene(
                                      except: Scenes.mainmenu,
                                      arguments: {
                                        'reset':
                                            GameData.game['saveName'] != 'debug'
                                      });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(color: GameUI.foregroundColor),
                    ),
                    child: fluent.FlyoutTarget(
                      controller: menuController,
                      child: IconButton(
                        icon: const Icon(Icons.menu_open, size: 20.0),
                        mouseCursor: MouseCursor.defer,
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          showFluentMenu<WorldEditorDropMenuItems>(
                            controller: menuController,
                            items: {
                              engine.locale('save'):
                                  WorldEditorDropMenuItems.save,
                              engine.locale('saveAs'):
                                  WorldEditorDropMenuItems.saveAs,
                              engine.locale('saveMapAs'):
                                  WorldEditorDropMenuItems.saveMapAs,
                              '___0': null,
                              engine.locale('addWorld'):
                                  WorldEditorDropMenuItems.addWorld,
                              engine.locale('switchWorld'):
                                  WorldEditorDropMenuItems.switchWorld,
                              engine.locale('deleteWorld'):
                                  WorldEditorDropMenuItems.deleteWorld,
                              engine.locale('expandWorld'):
                                  WorldEditorDropMenuItems.expandWorld,
                              '___1': null,
                              engine.locale('view'): {
                                engine.locale('none'):
                                    WorldEditorDropMenuItems.viewNone,
                                engine.locale('zone'):
                                    WorldEditorDropMenuItems.viewZones,
                                engine.locale('organization'):
                                    WorldEditorDropMenuItems.viewOrganizations,
                              },
                              '___2': null,
                              engine.locale('generateZone'):
                                  WorldEditorDropMenuItems.generateZone,
                              engine.locale('reloadGameData'):
                                  WorldEditorDropMenuItems.reloadGameData,
                              engine.locale('characterCalculateStats'):
                                  WorldEditorDropMenuItems
                                      .characterCalculateStats,
                              '___3': null,
                              engine.locale('console'):
                                  WorldEditorDropMenuItems.console,
                              '___4': null,
                              engine.locale('exit'):
                                  WorldEditorDropMenuItems.exit,
                            },
                            onSelectedItem:
                                (WorldEditorDropMenuItems item) async {
                              switch (item) {
                                case WorldEditorDropMenuItems.addWorld:
                                  final args = await showDialog(
                                    context: context,
                                    builder: (context) => CreateBlankMapDialog(
                                      isCreatingNewGame: false,
                                      isEditorMode: true,
                                    ),
                                  );
                                  if (args == null) return;

                                  engine.pushScene(args['id'],
                                      constructorId: Scenes.worldmap,
                                      arguments: args);
                                case WorldEditorDropMenuItems.switchWorld:
                                  final worldId = await GameLogic.selectWorld();
                                  if (worldId == null) return;
                                  if (worldId == worldData['id']) return;
                                  engine.hetu.invoke('setCurrentWorld',
                                      positionalArgs: [worldId]);

                                  if (engine.hasScene(worldId)) {
                                    engine.switchScene(worldId);
                                  } else {
                                    engine.pushScene(
                                      worldId,
                                      constructorId: Scenes.worldmap,
                                      arguments: {
                                        'id': worldId,
                                        'method': 'load',
                                        'isEditorMode': true,
                                      },
                                    );
                                  }
                                case WorldEditorDropMenuItems.deleteWorld:
                                  final worldId = await GameLogic.selectWorld();
                                  if (worldId == null) return;
                                  if (worldId == worldData['id']) return;
                                  final result = await showDialog<bool?>(
                                    context: context,
                                    builder: (context) => ConfirmDialog(
                                        description: engine
                                            .locale('dangerOperationPrompt')),
                                  );
                                  if (result == true) {
                                    GameData.worldIds.remove(worldId);
                                    engine.hetu.invoke('deleteWorldById',
                                        positionalArgs: [worldId]);
                                  }
                                case WorldEditorDropMenuItems.expandWorld:
                                  final value =
                                      await showDialog<(int, int, String)>(
                                          context: context,
                                          builder: (context) =>
                                              const ExpandWorldDialog());
                                  if (value == null) return;
                                  engine.hetu.invoke('expandCurrentWorldBySize',
                                      positionalArgs: [
                                        value.$1,
                                        value.$2,
                                        value.$3
                                      ]);
                                  map.loadTerrainData();
                                case WorldEditorDropMenuItems.save:
                                  String worldId = GameData.world['id'];
                                  String? saveName = engine.hetu
                                      .fetch('saveName', namespace: 'game');
                                  final saveInfo = await context
                                      .read<GameSavesState>()
                                      .saveGame(worldId, saveName);
                                  if (saveInfo != null) {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('savedSuccessfully',
                                          interpolations: [saveInfo.savePath]),
                                    );
                                  } else {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('saveFailed'),
                                    );
                                  }
                                case WorldEditorDropMenuItems.saveAs:
                                  final saveName = await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return InputStringDialog(
                                        title: engine.locale('inputName'),
                                      );
                                    },
                                  );
                                  if (saveName == null) return;
                                  engine.hetu.assign('saveName', saveName,
                                      namespace: 'game');
                                  String worldId = GameData.world['id'];
                                  final saveInfo = await context
                                      .read<GameSavesState>()
                                      .saveGame(worldId, saveName);
                                  if (saveInfo != null) {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('savedSuccessfully',
                                          interpolations: [saveInfo.savePath]),
                                    );
                                  } else {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('saveFailed'),
                                    );
                                  }
                                case WorldEditorDropMenuItems.saveMapAs:
                                  String worldId = worldData['id'];
                                  final saveName = await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return InputStringDialog(
                                        title: engine.locale('inputName'),
                                        value: worldId,
                                      );
                                    },
                                  );
                                  if (saveName == null) return;
                                  final savePath = await context
                                      .read<GameSavesState>()
                                      .saveMap(worldId, saveName);
                                  if (savePath != null) {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('savedSuccessfully',
                                          interpolations: [savePath]),
                                    );
                                  } else {
                                    GameDialogContent.show(
                                      context,
                                      engine.locale('saveFailed'),
                                    );
                                  }
                                case WorldEditorDropMenuItems.viewNone:
                                  map.colorMode = kColorModeNone;
                                case WorldEditorDropMenuItems.viewZones:
                                  map.colorMode = kColorModeZone;
                                case WorldEditorDropMenuItems.viewOrganizations:
                                  map.colorMode = kColorModeOrganization;
                                case WorldEditorDropMenuItems.generateZone:
                                  final count =
                                      GameLogic.generateZone(worldData);
                                  // final count = engine.hetu.invoke('generateZone',
                                  //     positionalArgs: [worldData]);
                                  engine.hetu.invoke('nameZones',
                                      positionalArgs: [worldData]);
                                  GameDialogContent.show(
                                    context,
                                    engine.locale(
                                      'generatedZone',
                                      interpolations: [count],
                                    ),
                                  );
                                  loadZoneColors();
                                case WorldEditorDropMenuItems.reloadGameData:
                                  GameData.initGameData();
                                  GameDialogContent.show(context,
                                      engine.locale('reloadGameDataPrompt'));
                                case WorldEditorDropMenuItems
                                      .characterCalculateStats:
                                  for (final character
                                      in GameData.game['characters'].values) {
                                    engine.hetu.invoke(
                                      'characterCalculateStats',
                                      positionalArgs: [character],
                                      namedArgs: {
                                        'reset': true,
                                        'rejuvenate': true,
                                      },
                                    );
                                  }
                                  GameDialogContent.show(
                                      context,
                                      engine.locale(
                                          'characterCalculateStatsPrompt'));
                                case WorldEditorDropMenuItems.console:
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => Console(
                                      engine: engine,
                                      margin: const EdgeInsets.all(50.0),
                                      backgroundColor: GameUI.backgroundColor2,
                                    ),
                                  );
                                case WorldEditorDropMenuItems.exit:
                                  context.read<SelectedPositionState>().clear();
                                  context.read<EditorToolState>().clear();
                                  engine.clearAllCachedScene(
                                      except: Scenes.mainmenu,
                                      arguments: {'reset': true});
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                EntityListPanel(
                  size: Size(390, GameUI.size.y),
                  onUpdateCharacters: _updateCharactersOnWorldMap,
                  onUpdateLocations: _updateWorldMapCaptions,
                  onCreatedOrganization: (organization, terrain) {
                    map.zoneColors[1][terrain.index] =
                        HexColor.fromString(organization['color']);
                  },
                ),
                Toolbox(),
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
        ),
      ],
    );
  }
}
