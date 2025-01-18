import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
import 'package:hetu_script/values.dart';
import 'package:flame/flame.dart';
import 'package:provider/provider.dart';

import '../../engine.dart';
import 'weather/cloud.dart';
import '../common.dart';
import '../../ui.dart';
import 'animation/flying_sword.dart';
import '../../data.dart';
import '../../state/states.dart';
import '../game_dialog/game_dialog.dart';
import '../../widgets/dialog/character_select_dialog.dart';
import '../../widgets/ui_overlay.dart';
import '../quest_info.dart';
import '../npc_list.dart';
import '../../widgets/history_panel.dart';
import '../../widgets/dialog/input_string.dart';
import '../../widgets/world_infomation/world_infomation.dart';
import '../../widgets/menu_item_builder.dart';
import '../../events.dart';
import '../../widgets/dialog/input_world_position.dart';
import '../../widgets/location/location.dart';
import '../../widgets/common.dart';
import '../mainmenu/create_blank_map.dart';
import '../../widgets/dialog/select_menu_dialog.dart';
import 'widgets/drop_menu.dart';
import 'widgets/editor_drop_menu.dart';
import 'widgets/entity_list.dart';
import 'widgets/expand_world_dialog.dart';
import 'widgets/tile_detail.dart';
import 'widgets/tile_info.dart';
import 'widgets/toolbox.dart';

enum TerrainPopUpMenuItems {
  checkInformation,
  createLocation,
  bindObject,
  clearObject,
  empty,
  plain,
  forest,
  mountain,
  shore,
  lake,
  sea,
  river,
  road,
  clearTerrainSprite,
  clearTerrainAnimation,
  clearTerrainOverlaySprite,
  clearTerrainOverlayAnimation,
}

List<PopupMenuEntry<TerrainPopUpMenuItems>> buildEditTerrainPopUpMenuItems(
    {void Function(TerrainPopUpMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<TerrainPopUpMenuItems>>[
    buildMenuItem(
      item: TerrainPopUpMenuItems.checkInformation,
      name: engine.locale('checkInformation'),
      onSelectedItem: onSelectedItem,
    ),
    buildSubMenuItem(
      items: {
        engine.locale('void'): TerrainPopUpMenuItems.empty,
        engine.locale('plain'): TerrainPopUpMenuItems.plain,
        engine.locale('forest'): TerrainPopUpMenuItems.forest,
        engine.locale('mountain'): TerrainPopUpMenuItems.mountain,
        engine.locale('shore'): TerrainPopUpMenuItems.shore,
        engine.locale('lake'): TerrainPopUpMenuItems.lake,
        engine.locale('sea'): TerrainPopUpMenuItems.sea,
        engine.locale('river'): TerrainPopUpMenuItems.river,
        engine.locale('road'): TerrainPopUpMenuItems.road,
      },
      name: engine.locale('setTerrainKind'),
      offset: const Offset(120, 0),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.createLocation,
      name: engine.locale('createLocation'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(height: 12.0),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearTerrainSprite,
      name: engine.locale('clearTerrainSprite'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearTerrainAnimation,
      name: engine.locale('clearTerrainAnimation'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearTerrainOverlaySprite,
      name: engine.locale('clearTerrainOverlaySprite'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearTerrainOverlayAnimation,
      name: engine.locale('clearTerrainOverlayAnimation'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(height: 12.0),
    buildMenuItem(
      item: TerrainPopUpMenuItems.bindObject,
      name: engine.locale('bindObject'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearObject,
      name: engine.locale('clearObject'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

const kExcludeTerrainKindsOnLighting = ['void', 'mountain'];
const kMaxCloudsCount = 16;

class WorldMapScene extends Scene {
  Sprite? backgroundSprite;

  final String? backgroundSpriteId;

  final TileMap map;

  final HTStruct worldData;

  final bool isEditorMode;

  final math.Random random = math.Random();

  bool get isMainWorld => worldData['isMainWorld'] ?? false;

  late FpsComponent fps;

  final _focusNode = FocusNode();

  dynamic _heroData;

  bool _playerFreezed = false;
  set playerFreezed(bool value) {
    _playerFreezed = map.autoUpdateMovingObject = value;
  }

  Vector2? _menuPosition;

  TileMapTerrain? _heroAtTerrain;
  dynamic _heroAtZone;
  dynamic _heroAtNation;
  dynamic _heroAtLocation;
  Iterable<dynamic> _npcsInHeroPosition = [];

  void _setHeroTerrain(TileMapTerrain? terrain) {
    _heroAtTerrain = terrain;
    if (_heroAtTerrain == null) return;
    final zoneId = _heroAtTerrain!.zoneId;
    if (zoneId != null) {
      _heroAtZone = engine.hetu.invoke('getZoneById', positionalArgs: [zoneId]);
    } else {
      _heroAtZone = null;
    }
    final nationId = _heroAtTerrain!.nationId;
    if (nationId != null) {
      _heroAtNation =
          engine.hetu.invoke('getOrganizationById', positionalArgs: [nationId]);
    } else {
      _heroAtNation = null;
    }
    final String? locationId = _heroAtTerrain!.locationId;
    if (locationId != null) {
      _heroAtLocation =
          engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);
    } else {
      _heroAtLocation = null;
    }
    context.read<SelectedTileState>().update(
          currentZoneData: _heroAtZone,
          currentNationData: _heroAtNation,
          currentLocationData: _heroAtLocation,
          currentTerrainObject: _heroAtTerrain,
        );
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
      _selectedLocation =
          engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);
    } else {
      _selectedLocation = null;
    }

    context.read<SelectedTileState>().update(
          currentZoneData: _selectedZone,
          currentNationData: _selectedNation,
          currentLocationData: _selectedLocation,
          currentTerrainObject: _selectedTerrain,
        );
  }

  bool _isDragging = false;

  WorldMapScene({
    required super.context,
    required this.worldData,
    required this.isEditorMode,
    this.backgroundSpriteId,
    super.bgmFile,
  })  : map = TileMap(
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
          tileObjectSpriteSrcSize: kTileMapObjectSpriteSrcSize,
          showSelected: true,
          showHover: true,
          showGrids: isEditorMode,
          showFogOfWar: !isEditorMode,
          showNonInteractableHintColor: isEditorMode,
          autoUpdateMovingObject: false,
          fogSpriteId: 'shadow.png',
          // isCameraFollowHero: false,
          // backgroundSpriteId: 'universe.png',
        ),
        super(
          id: worldData['id'],
          bgmVolume: GameConfig.musicVolume,
        );

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);

    // for (final cloud in _clouds) {
    //   cloud.update(dt);
    // }

    if (!isEditorMode && isMainWorld) {
      final r = math.Random().nextDouble();
      if (r < 0.01) {
        _addCloud();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    backgroundSprite?.render(canvas, size: size);

    super.render(canvas);

    if (!isEditorMode && (GameConfig.isDebugMode || GameConfig.showFps)) {
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

  @override
  Future<void> onLoad() async {
    super.onLoad();

    camera.zoom = 2.0;

    if (backgroundSpriteId != null) {
      backgroundSprite = Sprite(await Flame.images.load(backgroundSpriteId!));
    }

    map.onLoadComplete =
        isEditorMode ? _onMapLoadedInEditorMode : _onMapLoadedInGameMode;

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

    world.add(map);

    if (isMainWorld) {
      for (var i = 0; i < kMaxCloudsCount ~/ 2; ++i) {
        _addCloud();
      }
    }

    fps = FpsComponent();
  }

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) {
    super.onStart(arguments);

    map.onTapDown =
        isEditorMode ? _onMapTapDownInEditorMode : _onMapTapDownInGameMode;
    map.onTapUp =
        isEditorMode ? _onMapTapUpInEditorMode : _onMapTapUpInGameMode;
    map.onDragUpdate = (int buttons, Vector2 offset) {
      if (buttons == kSecondaryButton) {
        _isDragging = true;
        camera.moveBy(-camera.localToGlobal(offset) / camera.zoom);
      }
    };

    if (isEditorMode) {
      engine.hetu.interpreter.bindExternalFunction('setTerrainCaption', (
          {positionalArgs, namedArgs}) {
        map.setTerrainCaption(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('updateTerrainSprite', (
          {positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.tryLoadSprite();
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('updateTerrainOverlaySprite',
          ({positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.tryLoadSprite(isOverlay: true);
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('clearTerrainSprite', (
          {positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearSprite();
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('clearTerrainAnimation', (
          {positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearAnimation();
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlaySprite',
          ({positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearOverlaySprite();
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction(
          'clearTerrainOverlayAnimation', ({positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearOverlayAnimation();
      }, override: true);

      engine.setEventListener(
        Scenes.editor,
        GameEvents.worldmapCharactersUpdated,
        (eventId, args) async {
          _updateCharactersOnWorldMap();
        },
      );
    } else {
      engine.hetu.interpreter.bindExternalFunction('setTerrainCaption', (
          {positionalArgs, namedArgs}) {
        map.setTerrainCaption(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('updateTerrainSprite', (
          {positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.tryLoadSprite();
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('updateTerrainOverlaySprite',
          ({positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.tryLoadSprite(isOverlay: true);
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('clearTerrainAnimation', (
          {positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearAnimation();
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlaySprite',
          ({positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearOverlaySprite();
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction(
          'clearTerrainOverlayAnimation', ({positionalArgs, namedArgs}) {
        final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearOverlayAnimation();
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('setPlayerFreeze', (
          {positionalArgs, namedArgs}) {
        playerFreezed = positionalArgs.first;
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('updateHeroTileInfo', (
          {positionalArgs, namedArgs}) {
        map.hero!.tilePosition = TilePosition(
            _heroData['worldPosition']['left'],
            _heroData['worldPosition']['top']);
        map.updateTileInfo(map.hero!);
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('setObjectTo', (
          {positionalArgs, namedArgs}) {
        assert(map.movingObjects.containsKey(positionalArgs[0]));
        final object = map.movingObjects[positionalArgs[0]]!;
        object.tilePosition =
            TilePosition(positionalArgs[1], positionalArgs[2]);
        map.updateTileInfo(object);
        engine.hetu.invoke('setEntityWorldPosition', positionalArgs: [
          object.data,
          positionalArgs[1],
          positionalArgs[2]
        ]);
      });

      engine.hetu.interpreter.bindExternalFunction('moveObjectTo', (
          {positionalArgs, namedArgs}) {
        assert(map.movingObjects.containsKey(positionalArgs[0]));
        final completer = Completer();
        final int toX = positionalArgs[1];
        final int toY = positionalArgs[2];
        final String? endDirString = namedArgs['endDirection'];
        OrthogonalDirection? finishMoveDirection;
        if (endDirString != null) {
          finishMoveDirection = OrthogonalDirection.values
              .singleWhere((element) => element.name == endDirString);
        }
        final HTFunction? onAfterMoveCallback =
            namedArgs['onAfterMoveCallback'];
        final object = map.movingObjects[positionalArgs[0]]!;
        final route = _calculateRoute(
            fromX: object.left, fromY: object.top, toX: toX, toY: toY);
        if (route != null) {
          map.moveObjectToTilePositionByRoute(
            object,
            List<int>.from(route),
            finishMoveDirection: finishMoveDirection,
            onAfterMoveCallback: (tile, [nonEnterableDestination]) {
              onAfterMoveCallback?.call(
                  positionalArgs: [tile.data, nonEnterableDestination?.data]);
              completer.complete();
            },
          );
        } else {
          engine.error(
              'cannot move ${object.id} from position [${object.tilePosition}] to [$toX, $toY]}');
          completer.complete();
        }
        return completer.future;
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction(
          'updateNpcsInHeroWorldMapPosition',
          ({positionalArgs, namedArgs}) => _updateNpcsInHeroWorldMapPosition(),
          override: true);

      engine.hetu.interpreter.bindExternalFunction('updateNpcsInHeroLocation',
          ({positionalArgs, namedArgs}) => _updateNpcsInHeroLocation(),
          override: true);

      engine.hetu.interpreter.bindExternalFunction('addHintText', (
          {positionalArgs, namedArgs}) {
        final hexString = positionalArgs[3];
        Color? color;
        if (hexString != null) {
          color = HexColor.fromString(hexString);
        }
        addHintTextByTilePosition(
          positionalArgs[0],
          positionalArgs[1],
          positionalArgs[2],
          color: color,
        );
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction(
          'moveCameraToMapPosition',
          ({positionalArgs, namedArgs}) => map.moveCameraToTilePosition(
              positionalArgs[0], positionalArgs[1]),
          override: true);

      engine.hetu.interpreter.bindExternalFunction('lightUpAroundTile', (
          {positionalArgs, namedArgs}) {
        map.lightUpAroundTile(
          TilePosition(positionalArgs[0], positionalArgs[1]),
          size: positionalArgs[2],
        );
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction(
          'enterLocation',
          ({positionalArgs, namedArgs}) =>
              _tryEnterLocation(positionalArgs.first),
          override: true);

      engine.hetu.interpreter.bindExternalFunction('showFog', (
          {positionalArgs, namedArgs}) {
        map.showFogOfWar = positionalArgs.first;
      }, override: true);

      engine.hetu.interpreter.bindExternalFunction('switchWorld', (
          {positionalArgs, namedArgs}) {
        return context.read<SceneControllerState>().push(
          positionalArgs.first,
          constructorId: Scenes.worldmap,
          arguments: {'id': positionalArgs.first, 'method': 'load'},
        );
      }, override: true);
    }
  }

  void _addCloud() {
    final cloud = AnimatedCloud();
    cloud.position = map.getRandomTerrainPosition();
    world.add(cloud);
  }

  /// start & end are flame game canvas world position.
  void _useMapSkillFlyingSword(Vector2 start, Vector2 end) {
    final swordAnim = FlyingSword(start: start, end: end);
    map.add(swordAnim);
  }

  Future<void> _updateCharactersOnWorldMap() async {
    Iterable<dynamic> charsOnWorldMap =
        engine.hetu.invoke('getCharactersOnWorldMap', positionalArgs: [map.id]);

    final charIds = charsOnWorldMap.map((value) => value['id']);

    final toBeRemoved = [];
    for (final obj in map.movingObjects.values) {
      if (!charIds.contains(obj.id)) {
        toBeRemoved.add(obj.id);
      }
    }

    for (final id in toBeRemoved) {
      map.removeMovingObject(id);
    }

    for (final char in charsOnWorldMap) {
      final charId = char['id'];
      if (!map.movingObjects.containsKey(charId)) {
        map.loadMovingObjectFromData(char);
      } else {
        assert(char['worldPosition'] != null);
        final object = map.movingObjects[charId]!;
        object.tilePosition = TilePosition(
            char['worldPosition']['left'], char['worldPosition']['top']);
        map.updateTileInfo(object);
      }
    }
  }

  void _onMapTapDownInEditorMode(int buttons, Vector2 position) {
    _isDragging = false;

    final tilePosition = map.worldPosition2Tile(position);
    if (tilePosition != map.selectedTerrain?.tilePosition) {
      if (map.trySelectTile(tilePosition.left, tilePosition.top)) {
        _setSelectedTerrain(map.selectedTerrain);
      }
    }
  }

  void _onMapTapUpInEditorMode(int buttons, Vector2 position) {
    _focusNode.requestFocus();
    final tilePosition = map.worldPosition2Tile(position);
    final toolId = context.read<EditorToolState>().selectedId;
    if (buttons == kPrimaryButton) {
      // print('zoom: ${camera.zoom}');
      // print('position: $position');
      // print('cemara positon: ${camera.viewfinder.position}');
      // print((position - camera.viewfinder.position) *
      //         camera.viewfinder.zoom +
      //     size / 2);
      // print(map.worldPosition2Screen(position));
      if (tilePosition == map.selectedTerrain?.tilePosition) {
        if (toolId != null) {
          switch (toolId) {
            case 'delete':
              _selectedTerrain!.clearAllSprite();
            case 'nonInteractable':
              _selectedTerrain!.isNonEnterable =
                  !_selectedTerrain!.isNonEnterable;
            default:
              assert(GameData.tilesData.containsKey(toolId));
              final toolItemData = GameData.tilesData[toolId]!;
              switch (toolItemData['type']) {
                case 'terrain':
                  final HTStruct spriteData =
                      engine.hetu.interpreter.createStructfromJSON({
                    'kind': toolItemData['kind'],
                    'spriteIndex': toolItemData['spriteIndex'],
                  });
                  _selectedTerrain!.overrideSpriteData(spriteData);
                case 'overlaySprite':
                  final HTStruct overlayData =
                      engine.hetu.interpreter.createStructfromJSON({
                    'overlaySprite': toolItemData['overlaySprite'],
                  });
                  _selectedTerrain!
                      .overrideSpriteData(overlayData, isOverlay: true);
              }
          }
        }
      }
    } else if (buttons == kSecondaryButton) {
      if (_isDragging == true) {
        return;
      } else {
        context.read<EditorToolState>().clear();
      }
      if (tilePosition == map.selectedTerrain?.tilePosition) {
        final screenPosition = map.worldPosition2Screen(position);
        final popUpMenuPosition = RelativeRect.fromLTRB(
            screenPosition.x,
            screenPosition.y + map.gridSize.y * camera.zoom,
            screenPosition.x + map.gridSize.x * camera.zoom,
            0.0);
        final items = buildEditTerrainPopUpMenuItems(onSelectedItem: (item) {
          switch (item) {
            case TerrainPopUpMenuItems.checkInformation:
              showDialog(
                  context: context,
                  builder: (context) => const TileDetailPanel());
            case TerrainPopUpMenuItems.createLocation:
              InputWorldPositionDialog.show(
                context: context,
                defaultX: tilePosition.left,
                defaultY: tilePosition.top,
                maxX: map.tileMapWidth,
                maxY: map.tileMapHeight,
                title: engine.locale('createLocation'),
                enableWorldId: false,
              ).then(((int, int, String?)? value) {
                if (value == null) return;
                assert(context.mounted);
                if (context.mounted) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return LocationView(
                          mode: InformationViewMode.create,
                          left: value.$1,
                          top: value.$2,
                        );
                      });
                }
              });
            case TerrainPopUpMenuItems.bindObject:
              showDialog(
                context: context,
                builder: (context) => const InputStringDialog(),
              ).then((value) {
                if (value == null) return;
                _selectedTerrain!.objectId = value;
                _selectedTerrain!.caption = value;
              });
            case TerrainPopUpMenuItems.clearObject:
              _selectedTerrain!.objectId = null;
              _selectedTerrain!.caption = null;
            case TerrainPopUpMenuItems.empty:
              _selectedTerrain!.kind = kTerrainKindVoid;
            case TerrainPopUpMenuItems.plain:
              _selectedTerrain!.kind = kTerrainKindPlain;
            case TerrainPopUpMenuItems.forest:
              _selectedTerrain!.kind = kTerrainKindForest;
            case TerrainPopUpMenuItems.mountain:
              _selectedTerrain!.kind = kTerrainKindMountain;
            case TerrainPopUpMenuItems.shore:
              _selectedTerrain!.kind = kTerrainKindShore;
            case TerrainPopUpMenuItems.lake:
              _selectedTerrain!.kind = kTerrainKindLake;
            case TerrainPopUpMenuItems.sea:
              _selectedTerrain!.kind = kTerrainKindSea;
            case TerrainPopUpMenuItems.river:
              _selectedTerrain!.kind = kTerrainKindRiver;
            case TerrainPopUpMenuItems.road:
              _selectedTerrain!.kind = kTerrainKindRoad;
            case TerrainPopUpMenuItems.clearTerrainSprite:
              _selectedTerrain!.clearSprite();
            case TerrainPopUpMenuItems.clearTerrainAnimation:
              _selectedTerrain!.clearAnimation();
            case TerrainPopUpMenuItems.clearTerrainOverlaySprite:
              _selectedTerrain!.clearOverlaySprite();
            case TerrainPopUpMenuItems.clearTerrainOverlayAnimation:
              _selectedTerrain!.clearOverlayAnimation();
          }
          _setSelectedTerrain(map.selectedTerrain);
        });
        showMenu(
          context: context,
          position: popUpMenuPosition,
          items: items,
        );
      }
    }
  }

  Future<void> _onMapLoadedInEditorMode() async {
    engine.hetu.invoke('updateAllCaptions', namespace: 'Debug');
    await _updateCharactersOnWorldMap();
  }

  Future<void> _updateNpcsInHeroWorldMapPosition() async {
    _npcsInHeroPosition =
        engine.hetu.invoke('getNpcsByWorldMapPosition', positionalArgs: [
      _heroData?['worldPosition']['left'],
      _heroData?['worldPosition']['top'],
    ]);

    context.read<CurrentNpcList>().updated(_npcsInHeroPosition);
  }

  Future<void> _updateNpcsInHeroLocation() async {
    final npcsInHeroLocation =
        engine.hetu.invoke('getNpcsByLocationId', positionalArgs: [
      _heroData?['locationId'],
    ]);

    context.read<CurrentNpcList>().updated(npcsInHeroLocation);
  }

  Future<void> _updateMap() async {
    Iterable<dynamic> npcsOnWorldMap =
        engine.hetu.invoke('getNpcsOnWorldMap', positionalArgs: [map.id]);

    final charIds = npcsOnWorldMap.map((value) => value['id']);

    final toBeRemoved = [];
    for (final obj in map.movingObjects.values) {
      if (!charIds.contains(obj.id)) {
        toBeRemoved.add(obj.id);
      }
    }

    for (final id in toBeRemoved) {
      map.removeMovingObject(id);
    }

    for (final char in npcsOnWorldMap) {
      final charId = char['id'];
      if (!map.movingObjects.containsKey(charId)) {
        map.loadMovingObjectFromData(char, (left, top) {
          engine.hetu.invoke('setCharacterWorldPosition',
              positionalArgs: [char, left, top]);
        });
      } else {
        assert(char['worldPosition'] != null);
        final object = map.movingObjects[charId]!;
        object.tilePosition = TilePosition(
            char['worldPosition']['left'], char['worldPosition']['top']);
        map.updateTileInfo(object);
      }
    }

    _updateNpcsInHeroWorldMapPosition();

    context.read<HistoryState>().update();
  }

  void _heroMoveTo(TileMapTerrain terrain) {
    if (!map.isTileVisible(terrain.left, terrain.top)) return;
    final hero = map.hero!;
    if (hero.isWalking) return;
    if (terrain.terrainKind == TileMapTerrainKind.empty) return;

    final neighbors = map.getNeighborTilePositions(hero.left, hero.top);
    if (terrain.isNonEnterable && neighbors.contains(terrain.tilePosition)) {
      engine.hetu.invoke('senseTerrain', positionalArgs: [terrain.data]);
      return;
    } else {
      final movableTerrainKinds = engine.hetu
          .invoke('onBeforeHeroMove', positionalArgs: [terrain.data]);
      if (movableTerrainKinds == null || movableTerrainKinds.isEmpty) {
        return;
      }
      final calculatedRoute = _calculateRoute(
        fromX: hero.left,
        fromY: hero.top,
        toTile: terrain.data,
        terrainKinds: movableTerrainKinds,
      );
      if (calculatedRoute != null) {
        final route = List<int>.from(calculatedRoute);
        map.moveObjectToTilePositionByRoute(
          map.hero!,
          route,
          onAfterMoveCallback: (tile, [nonEnterableDestination]) {
            if (tile.objectId != null) {
              final object = engine.hetu
                  .invoke('getObjectById', positionalArgs: [tile.objectId]);
              if (object['blockHeroMove'] == true) {
                map.hero!.isMovingCanceled = true;
              }
            }
            // TODO: 某些情况下，让英雄返回上一格
            // map.moveObjectToPreviousTile(map.hero!);
            if (isMainWorld) {
              engine.hetu.invoke('updateGame');
            }
            engine.hetu.invoke('onAfterHeroMove',
                positionalArgs: [tile.data, nonEnterableDestination?.data]);
          },
          onFinishMoveCallback: () async {
            // final lightedAreaSize = _heroData!['stats']['lightRadius'];
            map.lightUpAroundTile(
              map.hero!.tilePosition,
              size: map.hero!.data['stats']['lightRadius'],
              // excludeTerrainKinds: kExcludeTerrainKindsOnLighting,
            );
            engine.hetu.invoke('setHeroWorldPosition', positionalArgs: [
              hero.tilePosition.left,
              hero.tilePosition.top
            ]);
            _setHeroTerrain(map.getTerrainAtHero());
            await _updateMap();
            // 如果英雄所在格子只有一个npc，则默认直接和该npc互动
            // if (_npcsInHeroPosition.length == 1) {
            //   final npcId = _npcsInHeroPosition.first['id'];
            //   engine.hetu.invoke('onInteractCharacter', positionalArgs: [npcId]);
            // }
          },
        );
      }
    }
  }

  Future<void> _interactTerrain(TileMapTerrain terrain) async {
    await engine.hetu
        .invoke('onInteractTerrain', positionalArgs: [terrain.data]);
  }

  Future<void> _tryEnterLocation(dynamic locationData) async {
    if (!(locationData['isDiscovered'] ?? false)) {
      engine.warn('location ${locationData['id']} is not discovered yet.');
      return;
    }

    await engine.hetu
        .invoke('onBeforeHeroEnterLocation', positionalArgs: [locationData]);

    assert(context.mounted);
    if (context.mounted) {
      context.read<SceneControllerState>().push(
        Scenes.location,
        arguments: {'location': locationData},
      );
    }
  }

  List? _calculateRoute({
    dynamic fromTile,
    dynamic toTile,
    int? fromX,
    int? fromY,
    int? toX,
    int? toY,
    List<dynamic> terrainKinds = const [],
  }) {
    assert(fromTile != null || (fromX != null && fromY != null));
    assert(toTile != null || (toX != null && toY != null));
    fromTile ??= engine.hetu.invoke('getTerrainByWorldPosition',
        positionalArgs: [fromX, fromY, worldData]);
    toTile ??= engine.hetu.invoke('getTerrainByWorldPosition',
        positionalArgs: [toX, toY, worldData]);
    List? calculatedRoute = engine.hetu.invoke(
      'calculateRoute',
      positionalArgs: [fromTile, toTile, worldData],
      namedArgs: {'terrainKinds': terrainKinds},
    );
    return calculatedRoute;
  }

  void _onMapTapDownInGameMode(int buttons, Vector2 position) {
    if (_menuPosition != null) return;
    if (GameDialog.isGameDialogOpened) return;

    final tilePosition = map.worldPosition2Tile(position);
    map.trySelectTile(tilePosition.left, tilePosition.top);
  }

  void _onMapTapUpInGameMode(int buttons, Vector2 position) {
    if (GameDialog.isGameDialogOpened) return;
    if (_playerFreezed) return;
    // addHintText('test', tilePosition.left, tilePosition.top);
    if (map.hero == null) return;

    _isDragging = false;

    final tilePosition = map.worldPosition2Tile(position);
    if (_menuPosition != null) {
      _menuPosition = null;
    } else {
      if (buttons == kPrimaryButton) {
        if (tilePosition == map.selectedTerrain?.tilePosition) {
          final terrain = map.selectedTerrain!;
          if (terrain.tilePosition != map.hero!.tilePosition) {
            _heroMoveTo(terrain);
          } else {
            if (terrain.locationId != null) {
              final locationData = engine.hetu.invoke('getLocationById',
                  positionalArgs: [terrain.locationId]);
              if (locationData['isDiscovered']) {
                _tryEnterLocation(locationData);
              }
            } else if (terrain.objectId != null) {
              final objectData = engine.hetu
                  .invoke('getObjectById', positionalArgs: [terrain.objectId]);
              if (objectData['isDiscovered']) {
                engine.hetu.invoke('onInteractObject',
                    positionalArgs: [objectData, terrain.data]);
              }
            }
          }
        }
      } else if (buttons == kSecondaryButton) {
        if (_isDragging) return;
        if (tilePosition == map.selectedTerrain?.tilePosition &&
            _heroAtTerrain != null) {
          if (!map.isTileVisible(_heroAtTerrain!.left, _heroAtTerrain!.top)) {
            return;
          }
          _menuPosition = map.tilePosition2TileCenterInScreen(
              _heroAtTerrain!.left, _heroAtTerrain!.top);
        }
      }
    }
  }

  Future<void> _onMapLoadedInGameMode() async {
    final isNewGame = GameData.data['isNewGame'];
    _heroData = engine.hetu.fetch('hero');
    if (isNewGame == true) {
      if (_heroData == null) {
        final charactersData = engine.hetu.invoke('getCharacters');
        final Iterable filteredCharacters =
            (charactersData as Iterable).where((character) {
          final age = engine.hetu
              .invoke('getCharacterAge', positionalArgs: [character]);
          if (age >= kMinHeroAge && age < kMaxHeroAge) {
            return true;
          }
          return false;
        });
        final key = await CharacterSelectDialog.show(
          context: context,
          title: engine.locale('selectHero'),
          charactersData: filteredCharacters,
          showCloseButton: false,
        );
        engine.hetu.invoke('setHeroId', positionalArgs: [key]);
        final heroHome = engine.hetu.invoke('getHeroHome');
        engine.hetu.invoke('discoverLocation', positionalArgs: [heroHome]);
        _heroData = engine.hetu.fetch('hero');
      }

      engine.hetu.invoke('onNewGame');
    }

    assert(_heroData != null);
    await map.loadHeroFromData(_heroData);
    assert(context.mounted);
    if (context.mounted) {
      context.read<GameUIOverlayVisibilityState>().setVisible();
      context.read<HeroState>().update();
    }

    engine.hetu.invoke('updateWorldMapCaptions');

    // final lightedAreaSize = _heroData!['stats']['lightRadius'];
    // map.lightUpAroundTile(
    //   map.hero!.tilePosition,
    //   size: _heroData!['stats']['lightRadius'],
    //   // excludeTerrainKinds: kExcludeTerrainKindsOnLighting,
    // );

    if (_heroData['worldPosition']?['worldId'] == map.id) {
      _setHeroTerrain(map.getTerrainAtHero());
      map.moveCameraToTilePosition(map.hero!.left, map.hero!.top,
          animated: false);
    }

    await _updateMap();

    assert(context.mounted);
    if (context.mounted) {
      context.read<HistoryState>().update();
    }
  }

  void closePopup() {
    _menuPosition = null;
  }

  void addHintTextByTilePosition(text, left, top,
      {double duration = 1.5, Color? color}) {
    final worldPosition = map.tilePosition2TileCenter(left, top);

    super.addHintText(
      text,
      position: worldPosition,
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

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          engine.debug('keydown: ${event.logicalKey.keyLabel}');
          switch (event.logicalKey) {
            case LogicalKeyboardKey.space:
              camera.zoom = 2.0;
              if (isEditorMode) {
                map.moveCameraToTileMapCenter();
              } else {
                map.moveCameraToHero();
              }
            case LogicalKeyboardKey.escape:
              if (isEditorMode) {
                context.read<EditorToolState>().clear();
              }
          }
        }
      },
      child: Stack(
        children: [
          SceneWidget(scene: this),
          if (!isEditorMode) ...[
            Positioned(
              left: 0,
              top: 0,
              child: GameUIOverlay(),
            ),
            const Positioned(
              right: 0,
              top: 100,
              child: QuestInfoPanel(),
            ),
            const Positioned(
              left: 20,
              top: 150,
              child: NpcList(),
            ),
            const Positioned(
              left: 0.0,
              bottom: 0.0,
              child: HistoryPanel(),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: WorldMapDropMenu(
                onSelected: (WorldMapDropMenuItems item) async {
                  switch (item) {
                    case WorldMapDropMenuItems.save:
                      map.saveMovingObjectsFrameData();
                      String worldId = engine.hetu.invoke('getCurrentWorldId');
                      String? saveName = engine.hetu.invoke('getSaveName');
                      context
                          .read<GameSavesState>()
                          .saveGame(worldId, saveName)
                          .then((saveInfo) {
                        if (context.mounted) {
                          GameDialog.show(
                            context: context,
                            dialogData: {
                              'lines': [
                                engine.locale('savedSuccessfully',
                                    interpolations: [saveInfo.savePath]),
                              ],
                            },
                          );
                        }
                      });

                    case WorldMapDropMenuItems.saveAs:
                      map.saveMovingObjectsFrameData();
                      showDialog(
                        context: context,
                        builder: (context) {
                          return InputStringDialog(
                            title: engine.locale('inputName'),
                          );
                        },
                      ).then((saveName) {
                        if (saveName == null) return;
                        engine.hetu
                            .invoke('setSaveName', positionalArgs: [saveName]);
                        String worldId =
                            engine.hetu.invoke('getCurrentWorldId');
                        if (context.mounted) {
                          context
                              .read<GameSavesState>()
                              .saveGame(worldId, saveName)
                              .then((saveInfo) {
                            if (context.mounted) {
                              GameDialog.show(
                                context: context,
                                dialogData: {
                                  'lines': [
                                    engine.locale('savedSuccessfully',
                                        interpolations: [saveInfo.savePath]),
                                  ],
                                },
                              );
                            }
                          });
                        }
                      });
                    case WorldMapDropMenuItems.info:
                      showDialog(
                          context: context,
                          builder: (context) => const WorldInformationPanel());
                    case WorldMapDropMenuItems.viewNone:
                      map.colorMode = kColorModeNone;
                    case WorldMapDropMenuItems.viewZones:
                      map.colorMode = kColorModeZone;
                    case WorldMapDropMenuItems.viewOrganizations:
                      map.colorMode = kColorModeOrganization;
                    case WorldMapDropMenuItems.console:
                      showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            Console(engine: engine),
                      );
                    case WorldMapDropMenuItems.exit:
                      context.read<SelectedTileState>().clear();
                      context.read<SceneControllerState>().clearAll(
                          except: Scenes.mainmenu, arguments: {'reset': true});
                  }
                },
              ),
            ),
          ] else ...[
            Positioned(
              right: 0,
              top: 0,
              child: WorldEditorDropMenu(
                onSelected: (WorldEditorDropMenuItems item) async {
                  switch (item) {
                    case WorldEditorDropMenuItems.addWorld:
                      final args = await showDialog(
                        context: context,
                        builder: (context) => CreateBlankMapDialog(
                          isCreatingNewGame: false,
                          isEditorMode: isEditorMode,
                        ),
                      );
                      if (args == null) return;

                      assert(context.mounted);
                      if (context.mounted) {
                        context.read<SceneControllerState>().push(args['id'],
                            constructorId: Scenes.worldmap, arguments: args);
                      }
                    case WorldEditorDropMenuItems.switchWorld:
                      final worldId = await showDialog(
                        context: context,
                        builder: (context) => SelectMenuDialog(
                            selections: {
                              for (var element in GameData.worldIds)
                                element: element
                            },
                            selectedValue: GameData.worldIds.firstWhere(
                                (element) =>
                                    element != GameData.currentWorldId)),
                      );
                      if (worldId == null) return;
                      if (worldId == worldData['id']) return;

                      engine.hetu.invoke('setCurrentWorldId',
                          positionalArgs: [worldId]);

                      assert(context.mounted);
                      if (context.mounted) {
                        if (engine.hasScene(worldId)) {
                          context
                              .read<SceneControllerState>()
                              .switchTo(worldId);
                        } else {
                          context.read<SceneControllerState>().push(
                            worldId,
                            constructorId: Scenes.worldmap,
                            arguments: {
                              'id': worldId,
                              'method': 'load',
                              'isEditorMode': true,
                            },
                          );
                        }
                      }
                    case WorldEditorDropMenuItems.expandWorld:
                      showDialog<(int, int, String)>(
                              context: context,
                              builder: (context) => const ExpandWorldDialog())
                          .then(((int, int, String)? value) {
                        if (value == null) return;
                        engine.hetu.invoke('expandCurrentWorldBySize',
                            positionalArgs: [value.$1, value.$2, value.$3]);
                        map.updateData();
                      });
                    case WorldEditorDropMenuItems.save:
                      String worldId = engine.hetu.invoke('getCurrentWorldId');
                      String? saveName = engine.hetu.invoke('getSaveName');
                      context
                          .read<GameSavesState>()
                          .saveGame(worldId, saveName)
                          .then((saveInfo) {
                        if (context.mounted) {
                          GameDialog.show(
                            context: context,
                            dialogData: {
                              'lines': [
                                engine.locale('savedSuccessfully',
                                    interpolations: [saveInfo.savePath]),
                              ],
                            },
                          );
                        }
                      });
                    case WorldEditorDropMenuItems.saveAs:
                      showDialog(
                        context: context,
                        builder: (context) {
                          return InputStringDialog(
                            title: engine.locale('inputName'),
                          );
                        },
                      ).then((saveName) {
                        if (saveName == null) return;
                        engine.hetu
                            .invoke('setSaveName', positionalArgs: [saveName]);
                        String worldId =
                            engine.hetu.invoke('getCurrentWorldId');
                        if (context.mounted) {
                          context
                              .read<GameSavesState>()
                              .saveGame(worldId, saveName)
                              .then((saveInfo) {
                            if (context.mounted) {
                              GameDialog.show(
                                context: context,
                                dialogData: {
                                  'lines': [
                                    engine.locale('savedSuccessfully',
                                        interpolations: [saveInfo.savePath]),
                                  ],
                                },
                              );
                            }
                          });
                        }
                      });
                    case WorldEditorDropMenuItems.viewNone:
                      map.colorMode = kColorModeNone;
                    case WorldEditorDropMenuItems.viewZones:
                      map.colorMode = kColorModeZone;
                    case WorldEditorDropMenuItems.viewOrganizations:
                      map.colorMode = kColorModeOrganization;
                    case WorldEditorDropMenuItems.console:
                      showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            Console(engine: engine),
                      );
                    case WorldEditorDropMenuItems.exit:
                      context.read<SelectedTileState>().clear();
                      context.read<EditorToolState>().clear();
                      context.read<SceneControllerState>().clearAll(
                          except: Scenes.mainmenu, arguments: {'reset': true});
                  }
                },
              ),
            ),
            Positioned(
              child: EntityListPanel(
                size: Size(320, GameUI.size.y),
              ),
            ),
            const Positioned(
              right: 0,
              bottom: 0,
              child: TileInfoPanel(),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Toolbox(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
