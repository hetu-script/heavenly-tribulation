import 'dart:math' as math;
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

import '../../engine.dart';
import 'particles/cloud.dart';
import 'particles/rubble.dart';
import '../common.dart';
import '../../game/ui.dart';
import 'animation/flying_sword.dart';
import '../../game/data.dart';
import '../../state/states.dart';
import '../game_dialog/game_dialog_content.dart';
import '../../widgets/dialog/character_select.dart';
import '../../widgets/ui_overlay.dart';
// import '../../widgets/quest_panel.dart';
import '../../widgets/dialog/input_string.dart';
import '../../widgets/world_infomation.dart';
import '../../widgets/menu_item_builder.dart';
import '../mainmenu/create_blank_map.dart';
import 'widgets/drop_menu.dart';
import 'widgets/editor_drop_menu.dart';
import 'widgets/entity_list.dart';
import 'widgets/expand_world_dialog.dart';
import 'widgets/tile_detail.dart';
import 'widgets/tile_info.dart';
import 'widgets/toolbox.dart';
import '../../widgets/dialog/confirm.dart';
import '../../game/logic.dart';

enum TerrainPopUpMenuItems {
  checkInformation,
  createLocation,
  bindObject,
  clearObject,
  clearDecoration,
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
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearDecoration,
      name: engine.locale('clearDecoration'),
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

  bool _playerFreezed = false;
  set playerFreezed(bool value) {
    _playerFreezed = map.autoUpdateComponent = value;
  }

  Vector2? _menuPosition;

  // TileMapTerrain? _heroAtTerrain;
  // dynamic _heroAtZone;
  // dynamic _heroAtNation;
  // dynamic _heroAtLocation;
  final List<dynamic> _npcsInHeroPosition = [];

  // void _setHeroTerrain(TileMapTerrain? terrain) {
  //   _heroAtTerrain = terrain;
  //   if (_heroAtTerrain == null) return;
  //   final zoneId = _heroAtTerrain!.zoneId;
  //   if (zoneId != null) {
  //     _heroAtZone = engine.hetu.invoke('getZoneById', positionalArgs: [zoneId]);
  //   } else {
  //     _heroAtZone = null;
  //   }
  //   final nationId = _heroAtTerrain!.nationId;
  //   if (nationId != null) {
  //     _heroAtNation =
  //         engine.hetu.invoke('getOrganizationById', positionalArgs: [nationId]);
  //   } else {
  //     _heroAtNation = null;
  //   }
  //   final String? locationId = _heroAtTerrain!.locationId;
  //   if (locationId != null) {
  //     _heroAtLocation =
  //         engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);
  //   } else {
  //     _heroAtLocation = null;
  //   }
  //   // context.read<SelectedTileState>().update(
  //   //       currentZoneData: _heroAtZone,
  //   //       currentNationData: _heroAtNation,
  //   //       currentLocationData: _heroAtLocation,
  //   //       currentTerrainObject: _heroAtTerrain,
  //   //     );
  // }

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

  // bool _isInteracting = false;

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
          showSelected: true,
          showHover: true,
          showFogOfWar: !isEditorMode,
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

    if (!isEditorMode && (engine.config.debugMode || engine.config.showFps)) {
      drawScreenText(
        canvas,
        'FPS: ${fps.fps.toStringAsFixed(0)}',
        config: ScreenTextConfig(
          textStyle: const TextStyle(fontSize: 20),
          size: GameUI.size,
          anchor: Anchor.topRight,
          padding: const EdgeInsets.only(right: 50),
        ),
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

    map.onTapDown =
        isEditorMode ? _onMapTapDownInEditorMode : _onMapTapDownInGameMode;
    map.onTapUp =
        isEditorMode ? _onMapTapUpInEditorMode : _onMapTapUpInGameMode;
    map.onDragUpdate = (int buttons, Vector2 offset) {
      if (buttons == kSecondaryButton) {
        camera.moveBy(-camera.localToGlobal(offset) / camera.zoom);
      }
    };

    world.add(map);

    if (isMainWorld) {
      for (var i = 0; i < kMaxCloudsCount ~/ 2; ++i) {
        _addCloud();
      }
    }

    fps = FpsComponent();

    engine.hetu.interpreter.bindExternalFunction('World::setTerrainCaption', (
        {positionalArgs, namedArgs}) {
      map.setTerrainCaption(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::updateTerrainSprite', (
        {positionalArgs, namedArgs}) {
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.tryLoadSprite();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'World::updateTerrainOverlaySprite', ({positionalArgs, namedArgs}) {
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.tryLoadSprite(isOverlay: true);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::clearTerrainSprite', (
        {positionalArgs, namedArgs}) {
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearSprite();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::clearTerrainAnimation',
        ({positionalArgs, namedArgs}) {
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearAnimation();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'World::clearTerrainOverlaySprite', ({positionalArgs, namedArgs}) {
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearOverlaySprite();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'World::clearTerrainOverlayAnimation', ({positionalArgs, namedArgs}) {
      final tile = map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearOverlayAnimation();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::setPlayerFreeze', (
        {positionalArgs, namedArgs}) {
      playerFreezed = positionalArgs.first;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::setCharacterTo', (
        {positionalArgs, namedArgs}) async {
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
            final charData = engine.hetu
                .invoke('getCharacterById', positionalArgs: [charId]);
            charComponent = await map.loadTileMapComponentFromData(charData,
                spriteSrcSize: kWorldMapCharacterSpriteSrcSize,
                isCharacter: true);
          }
        }
        charComponent.tilePosition =
            TilePosition(positionalArgs[1], positionalArgs[2]);
        final direction = namedArgs['direction'];
        if (direction != null) {
          charComponent.direction = OrthogonalDirection.values
              .singleWhere((element) => element.name == direction);
        }
        map.updateTileInfo(charComponent);
      }
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

    engine.hetu.interpreter.bindExternalFunction('World::objectWalkTo', (
        {positionalArgs, namedArgs}) {
      final object = map.components[positionalArgs[0]];
      if (object == null) {
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
      final HTFunction? onBeforeStepCallback =
          namedArgs['onBeforeStepCallback'];

      final route = _calculateRoute(
          fromX: object.left, fromY: object.top, toX: toX, toY: toY);
      if (route != null) {
        assert(route.length > 1);
        map.componentWalkToTilePositionByRoute(
          object,
          List<int>.from(route),
          finishMoveDirection: finishMoveDirection,
          onStepCallback: (terrain, [targetTerrain]) {
            onBeforeStepCallback
                ?.call(positionalArgs: [terrain.data, targetTerrain?.data]);
            completer.complete();
          },
        );
      } else {
        engine.error(
            '无法将对象 ${object.id} 从大地图位置 [${object.tilePosition}] 移动到 [$toX, $toY]}');
        completer.complete();
      }
      return completer.future;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'World::updateNpcsAtWorldMapPosition',
        ({positionalArgs, namedArgs}) => _updateNpcsAtWorldMapPosition(),
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
      addHintTextByTilePosition(
        positionalArgs[0],
        positionalArgs[1],
        positionalArgs[2],
        color: color,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'World::moveCameraToMapPosition',
        ({positionalArgs, namedArgs}) => map.moveCameraToTilePosition(
              positionalArgs[0],
              positionalArgs[1],
              animated: namedArgs['animated'],
            ),
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
            _tryEnterLocation(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('World::showFog', (
        {positionalArgs, namedArgs}) {
      map.showFogOfWar = positionalArgs.first;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('World::switchWorld', (
        {positionalArgs, namedArgs}) {
      engine.pushScene(
        positionalArgs.first,
        constructorId: Scenes.worldmap,
        arguments: {'id': positionalArgs.first, 'method': 'load'},
      );
    }, override: true);

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
  }

  Future<void> _onEnterScene() async {
    context.read<HeroState>().update();
    context.read<GameTimestampState>().update();
    context.read<HeroAndGlobalHistoryState>().update();
    await _updateWorldMapNPC();
    engine.hetu.invoke('onWorldEvent', positionalArgs: ['onEnterMap']);
  }

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) async {
    super.onStart(arguments);

    if (isLoaded) {
      _onEnterScene();
    }
  }

  void _addCloud() {
    final cloud = ParticleCloud();
    cloud.position = map.getRandomTerrainPosition();
    world.add(cloud);
  }

  /// start & end are flame game canvas world position.
  void _useMapSkillFlyingSword(Vector2 start, Vector2 end) {
    final swordAnim = FlyingSword(start: start, end: end);
    map.add(swordAnim);
  }

  void _onMapTapDownInEditorMode(int buttons, Vector2 position) {
    _focusNode.requestFocus();
    if (buttons == kPrimaryButton) {
      final tilePosition = map.worldPosition2Tile(position);
      if (tilePosition != map.selectedTerrain?.tilePosition) {
        if (map.trySelectTile(tilePosition.left, tilePosition.top)) {
          _setSelectedTerrain(map.selectedTerrain);
        }
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
              assert(GameData.tiles.containsKey(toolId));
              final toolItemData = GameData.tiles[toolId]!;
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
                case 'component':
                  if (!map.components.values.any((component) =>
                      component.tilePosition ==
                      _selectedTerrain!.tilePosition)) {
                    final componentData = GameData.mapComponents[toolId];
                    final created = engine.hetu
                        .invoke('createMapComponent', positionalArgs: [
                      componentData,
                      _selectedTerrain!.tilePosition.left,
                      _selectedTerrain!.tilePosition.top,
                    ]);
                    map.loadTileMapComponentFromData(created);
                  }
              }
          }
        }
      }
    } else if (buttons == kSecondaryButton) {
      context.read<EditorToolState>().clear();
      if (tilePosition == map.selectedTerrain?.tilePosition) {
        final tileRenderPosition =
            map.selectedTerrain!.renderRect.topLeft.toVector2();
        final screenPosition = map.worldPosition2Screen(tileRenderPosition);
        final popUpMenuPositionX = screenPosition.x +
            (map.tileOffset.x + map.gridSize.x) * camera.zoom +
            10;
        final popUpMenuPositionY =
            screenPosition.y + (map.tileOffset.y) * camera.zoom + 10;
        final popUpMenuPosition = RelativeRect.fromLTRB(
            popUpMenuPositionX, popUpMenuPositionY, popUpMenuPositionX, 0.0);
        final items = buildEditTerrainPopUpMenuItems(onSelectedItem: (item) {
          switch (item) {
            case TerrainPopUpMenuItems.checkInformation:
              showDialog(
                  context: context,
                  builder: (context) => const TileDetailPanel());
            case TerrainPopUpMenuItems.createLocation:
              break;
            // InputWorldPositionDialog.show(
            //   context: context,
            //   defaultX: tilePosition.left,
            //   defaultY: tilePosition.top,
            //   maxX: map.tileMapWidth,
            //   maxY: map.tileMapHeight,
            //   title: engine.locale('createLocation'),
            //   enableWorldId: false,
            // ).then(((int, int, String?)? value) {
            //   if (value == null) return;
            //   assert(context.mounted);
            //   if (context.mounted) {
            //     showDialog(
            //         context: context,
            //         builder: (context) {
            //           return LocationView(
            //             mode: InformationViewMode.create,
            //             left: value.$1,
            //             top: value.$2,
            //           );
            //         });
            //   }
            // });
            case TerrainPopUpMenuItems.bindObject:
              showDialog(
                context: context,
                builder: (context) => const InputStringDialog(),
              ).then((value) {
                if (value == null) return;
                final hasObject =
                    engine.hetu.invoke('hasObject', positionalArgs: [value]);
                if (hasObject) {
                  _selectedTerrain!.objectId = value;
                  _selectedTerrain!.caption = value;
                } else {
                  if (context.mounted) {
                    GameDialogContent.show(
                      context,
                      engine
                          .locale('objectIdNonExist', interpolations: [value]),
                    );
                  }
                }
              });
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
    await _updateCharactersOnWorldMap();
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
      } else {
        if (!charactersOnWorldMap.contains(obj.id)) {
          toBeRemoved.add(obj.id);
        }
      }
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

  Future<void> _updateNpcsAtWorldMapPosition() async {
    _npcsInHeroPosition.clear();

    for (final id in GameData.heroData['companions']) {
      final charData = GameData.gameData['characters'][id];
      assert(charData != null);
      _npcsInHeroPosition.add(charData);
    }

    final otherNpcs =
        engine.hetu.invoke('getNpcsAtWorldMapPosition', positionalArgs: [
      GameData.heroData?['worldPosition']['left'],
      GameData.heroData?['worldPosition']['top'],
    ]);
    _npcsInHeroPosition.addAll(otherNpcs);
    context.read<NpcListState>().update(_npcsInHeroPosition);
  }

  Future<void> _updateNpcsAtLocation() async {
    _npcsInHeroPosition.clear();

    for (final id in GameData.heroData['companions']) {
      final charData = GameData.gameData['characters'][id];
      assert(charData != null);
      _npcsInHeroPosition.add(charData);
    }

    final otherNpcs =
        engine.hetu.invoke('getNpcsAtLocationId', positionalArgs: [
      GameData.heroData?['locationId'],
    ]);
    _npcsInHeroPosition.addAll(otherNpcs);

    context.read<NpcListState>().update(_npcsInHeroPosition);
  }

  Future<void> _updateWorldMapCaptions() async {
    final locations = engine.hetu.invoke('getLocations');
    for (final locationData in locations) {
      if (locationData['category'] == 'city' &&
          locationData['isDiscovered'] == true) {
        final int left = locationData['worldPosition']['left'];
        final int top = locationData['worldPosition']['top'];
        map.setTerrainCaption(left, top, locationData['name']);
      }
    }
    // final objects = engine.hetu.invoke('getObjects');
    // for (final objectData in objects) {
    //   if (isEditorMode) {
    //     final int left = locationData['worldPosition']['left'];
    //     final int top = locationData['worldPosition']['top'];
    //     map.setTerrainCaption(left, top, locationData['name']);
    //   }
    // }
  }

  Future<void> _updateWorldMapNPC() async {
    await _updateCharactersOnWorldMap();

    await _updateNpcsAtWorldMapPosition();

    if (context.mounted) {
      context.read<HeroAndGlobalHistoryState>().update();
    }
  }

  void _heroMoveTo(TileMapTerrain terrain) async {
    if (!terrain.isLighted) return;
    final hero = map.hero!;
    if (hero.isWalking) return;
    if (terrain.terrainKind == TileMapTerrainKind.none) return;

    final neighbors = map.getNeighborTilePositions(hero.left, hero.top);
    if (terrain.isNonEnterable && neighbors.contains(terrain.tilePosition)) {
      if (terrain.objectId != null) {
        _tryInteractObject(terrain.objectId!, terrain.data);
      }
      return;
    } else {
      final movableTerrainKinds = await engine.hetu
          .invoke('onBeforeMove', positionalArgs: [terrain.data]);
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
        assert(calculatedRoute.length > 1);
        final route = List<int>.from(calculatedRoute);
        map.componentWalkToTilePositionByRoute(
          map.hero!,
          route,
          onStepCallback: (terrain, next) async {
            if (next?.objectId != null) {
              // 如果下一个格子有物体，且该物体 blockMove 为 true
              // 意味着该物体会阻挡移动
              final objectData = engine.hetu
                  .invoke('getObjectById', positionalArgs: [next!.objectId]);
              if (objectData['blockMove'] == true) {
                map.hero!.isWalkCanceled = true;
                engine.hetu.invoke('onInteractMapObject',
                    positionalArgs: [objectData, next.data]);
                return;
              }
            }

            if (map.hero?.prevRouteNode != null) {
              map.lightUpAroundTile(
                terrain.tilePosition,
                size: map.hero!.data['stats']['lightRadius'],
                // excludeTerrainKinds: kExcludeTerrainKindsOnLighting,
              );
              await engine.hetu.invoke('onWorldEvent',
                  positionalArgs: ['onAfterMove', terrain.data]);
              // TODO: 某些情况下，让英雄返回上一格
              // map.objectWalkToPreviousTile(map.hero!);
              if (isMainWorld) {
                await engine.hetu.invoke('updateGame');
              }
            }
          },
          onFinishCallback: (terrain, [target]) async {
            // final lightedAreaSize = _heroData!['stats']['lightRadius'];
            // _setHeroTerrain(map.getTerrainAtHero());
            engine.hetu.invoke('setCharacterWorldPosition', positionalArgs: [
              GameData.heroData,
              hero.tilePosition.left,
              hero.tilePosition.top
            ]);
            // 刷新地图上的NPC，这一步只需要在整个移动结束后执行
            await _updateWorldMapNPC();

            if (target != null && target.objectId != null) {
              _tryInteractObject(target.objectId!, target.data);
            } else {
              if (terrain.objectId != null) {
                _tryInteractObject(terrain.objectId!, terrain.data);
              } else if (terrain.locationId != null) {
                final location = engine.hetu.invoke('getLocationById',
                    positionalArgs: [terrain.locationId]);
                _tryEnterLocation(location);
              }
            }

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

  // Future<void> _interactTerrain(TileMapTerrain terrain) async {
  //   await engine.hetu
  //       .invoke('onInteractTerrain', positionalArgs: [terrain.data]);
  // }

  void _tryInteractObject(String objectId, dynamic terrainData) {
    final objectData =
        engine.hetu.invoke('getObjectById', positionalArgs: [objectId]);
    engine.hetu.invoke('onInteractMapObject',
        positionalArgs: [objectData, terrainData]);
  }

  Future<void> _tryEnterLocation(dynamic locationData) async {
    final result = await engine.hetu
        .invoke('onBeforeEnterLocation', positionalArgs: [locationData]);

    if (result == null) {
      engine.pushScene(
        locationData['id'],
        constructorId: Scenes.location,
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
    _focusNode.requestFocus();

    if (_menuPosition != null) return;
    // if (GameDialog.isGameDialogOpened) return;

    final tilePosition = map.worldPosition2Tile(position);
    map.trySelectTile(tilePosition.left, tilePosition.top);
  }

  void _onMapTapUpInGameMode(int buttons, Vector2 position) async {
    // if (GameDialog.isGameDialogOpened) return;
    if (_playerFreezed) return;
    // addHintText('test', tilePosition.left, tilePosition.top);
    if (map.hero == null) return;
    // if (_isInteracting) return;

    final isGameDialogOpened = context.read<GameDialogState>().isOpened;
    if (isGameDialogOpened) return;

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
              _tryEnterLocation(locationData);
            } else if (terrain.objectId != null) {
              _tryInteractObject(terrain.objectId!, terrain.data);
            }
          }
        }
      } else if (buttons == kSecondaryButton) {
        // if (_heroAtTerrain != null &&
        //     tilePosition == _heroAtTerrain!.tilePosition) {
        //   _menuPosition = map.tilePosition2TileCenterInScreen(
        //       _heroAtTerrain!.left, _heroAtTerrain!.top);
        // }
      }
    }
  }

  Future<void> _onMapLoadedInGameMode() async {
    final isNewGame = GameData.gameData['isNewGame'];
    if (isNewGame == true) {
      engine.hetu.invoke('updateGame', namedArgs: {
        'timeflow': false,
        'moduleEvent': false,
      });

      if (GameData.heroData == null) {
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
        final heroHomeLocation = engine.hetu.invoke('getHeroHomeLocation');
        engine.hetu
            .invoke('discoverLocation', positionalArgs: [heroHomeLocation]);
        GameData.heroData = engine.hetu.fetch('hero');
      }
    }

    assert(GameData.heroData != null);
    await map.loadHeroFromData(
        GameData.heroData, kWorldMapCharacterSpriteSrcSize);

    _updateWorldMapCaptions();

    if (GameData.heroData['worldId'] == map.id) {
      // _setHeroTerrain(map.getTerrainAtHero());
      map.moveCameraToTilePosition(map.hero!.left, map.hero!.top,
          animated: false);
    }

    if (map.data['useCustomLogic'] != true) {
      map.lightUpAroundTile(map.hero!.tilePosition,
          size: GameData.heroData['stats']['lightRadius']);

      GameData.heroData['locationId'] = null;
    }

    await _updateWorldMapNPC();

    assert(context.mounted);
    if (context.mounted) {
      context.read<HeroState>().update();
      context.read<HeroInfoVisibilityState>().setVisible(isNewGame
          ? (map.data['useCustomLogic'] != true ? true : false)
          : null);
      context.read<HeroAndGlobalHistoryState>().update();
    }

    await engine.hetu.invoke('onNewGame');

    await _onEnterScene();
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
          engine.debug('keydown: ${event.logicalKey.debugName}');
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
              }
          }
        }
      },
      child: Stack(
        children: [
          SceneWidget(scene: this),
          if (!isEditorMode) ...[
            // const Positioned(
            //   right: 0,
            //   top: 100,
            //   child: QuestPanel(),
            // ),
            Positioned(
              left: 0,
              top: 0,
              child: GameUIOverlay(
                dropMenu: WorldMapDropMenu(
                  onSelected: (WorldMapDropMenuItems item) async {
                    switch (item) {
                      case WorldMapDropMenuItems.save:
                        map.saveComponentsFrameData();
                        String worldId = engine.hetu
                            .fetch('currentWorldId', namespace: 'game');
                        String? saveName =
                            engine.hetu.fetch('saveName', namespace: 'game');
                        context
                            .read<GameSavesState>()
                            .saveGame(worldId, saveName)
                            .then((saveInfo) {
                          if (context.mounted) {
                            GameDialogContent.show(
                              context,
                              engine.locale('savedSuccessfully',
                                  interpolations: [saveInfo.savePath]),
                            );
                          }
                        });

                      case WorldMapDropMenuItems.saveAs:
                        map.saveComponentsFrameData();
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
                              .assign('saveName', saveName, namespace: 'game');
                          String worldId = engine.hetu
                              .fetch('currentWorldId', namespace: 'game');
                          if (context.mounted) {
                            context
                                .read<GameSavesState>()
                                .saveGame(worldId, saveName)
                                .then((saveInfo) {
                              if (context.mounted) {
                                GameDialogContent.show(
                                  context,
                                  engine.locale('savedSuccessfully',
                                      interpolations: [saveInfo.savePath]),
                                );
                              }
                            });
                          }
                        });
                      case WorldMapDropMenuItems.info:
                        showDialog(
                            context: context,
                            builder: (context) =>
                                const WorldInformationPanel());
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
                            backgroundColor: GameUI.backgroundColor,
                          ),
                        );
                      case WorldMapDropMenuItems.exit:
                        context.read<SelectedTileState>().clear();
                        engine.clearAllCachedScene(
                            except: Scenes.mainmenu,
                            arguments: {'reset': true});
                    }
                  },
                ),
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

                      engine.pushScene(args['id'],
                          constructorId: Scenes.worldmap, arguments: args);
                    case WorldEditorDropMenuItems.switchWorld:
                      final worldId = await GameLogic.selectWorldId();
                      if (worldId == null) return;
                      if (worldId == worldData['id']) return;
                      engine.hetu.invoke('setCurrentWorldId',
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
                      final worldId = await GameLogic.selectWorldId();
                      if (worldId == null) return;
                      if (worldId == worldData['id']) return;
                      if (context.mounted) {
                        final result = await showDialog<bool?>(
                          context: context,
                          builder: (context) => ConfirmDialog(
                              description:
                                  engine.locale('dangerOperationPrompt')),
                        );
                        if (result == true) {
                          GameData.worldIds.remove(worldId);
                          engine.hetu.invoke('deleteWorldById',
                              positionalArgs: [worldId]);
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
                        map.loadTerrainData();
                      });
                    case WorldEditorDropMenuItems.save:
                      String worldId = engine.hetu
                          .fetch('currentWorldId', namespace: 'game');
                      String? saveName =
                          engine.hetu.fetch('saveName', namespace: 'game');
                      context
                          .read<GameSavesState>()
                          .saveGame(worldId, saveName)
                          .then((saveInfo) {
                        if (context.mounted) {
                          GameDialogContent.show(
                            context,
                            engine.locale('savedSuccessfully',
                                interpolations: [saveInfo.savePath]),
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
                            .assign('saveName', saveName, namespace: 'game');
                        String worldId = engine.hetu
                            .fetch('currentWorldId', namespace: 'game');
                        if (context.mounted) {
                          context
                              .read<GameSavesState>()
                              .saveGame(worldId, saveName)
                              .then((saveInfo) {
                            if (context.mounted) {
                              GameDialogContent.show(
                                context,
                                engine.locale('savedSuccessfully',
                                    interpolations: [saveInfo.savePath]),
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
                    case WorldEditorDropMenuItems.reloadGameData:
                      GameData.initGameData();
                      GameDialogContent.show(
                          context, engine.locale('reloadGameDataPrompt'));
                    case WorldEditorDropMenuItems.console:
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => Console(
                          engine: engine,
                          margin: const EdgeInsets.all(50.0),
                          backgroundColor: GameUI.backgroundColor,
                        ),
                      );
                    case WorldEditorDropMenuItems.exit:
                      context.read<SelectedTileState>().clear();
                      context.read<EditorToolState>().clear();
                      engine.clearAllCachedScene(
                          except: Scenes.mainmenu, arguments: {'reset': true});
                  }
                },
              ),
            ),
            EntityListPanel(
              size: Size(390, GameUI.size.y),
              onUpdateCharacters: _updateCharactersOnWorldMap,
              onUpdateLocations: _updateWorldMapCaptions,
            ),
            TileInfoPanel(),
            Toolbox(),
          ],
        ],
      ),
    );
  }
}
