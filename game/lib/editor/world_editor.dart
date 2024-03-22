import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:hetu_script/hetu_script.dart';
// import 'package:hetu_script/values.dart';
// import 'package:flame/flame.dart';
// import 'package:flame/sprite.dart';
import 'package:samsara/console.dart';
import 'package:provider/provider.dart';
import 'package:samsara/event.dart';

import 'components/expand_world_dialog.dart';
import '../data.dart';
// import '../../../event/ui.dart';
// import '../../../ui/view/information/information.dart';
// import '../../../shared/constants.dart';
import '../config.dart';
import '../scene/world/world.dart';
import 'components/drop_menu.dart';
// import '../../../ui/view/location/location.dart';
// import '../common.dart';
// import 'location/location.dart';
import '../state/selected_tile.dart';
import '../scene/world/common.dart';
import 'components/toolbox.dart';
import '../state/game_save.dart';
import '../dialog/game_dialog/game_dialog.dart';
import 'components/entity_list.dart';
import 'components/tile_info.dart';
import '../view/menu_item_builder.dart';
import 'components/tile_detail.dart';
import '../view/location/location.dart';
import '../dialog/input_world_position.dart';
import '../view/common.dart';
import '../events.dart';
import '../state/editor_tool.dart';
import '../dialog/input_string.dart';
import '../scene/loading_screen.dart';
import '../mainmenu/create_blank_map.dart';
import '../dialog/select_dialog.dart';
// import '../common.dart';

enum TerrainPopUpMenuItems {
  checkInformation,
  createLocation,
  bindMapObject,
  clearMapObject,
  empty,
  plain,
  forest,
  mountain,
  shore,
  lake,
  sea,
  river,
  road,
  clearTerrainAnimation,
  clearTerrainOverlaySprite,
  clearTerrainOverlayAnimation,
}

List<PopupMenuEntry<TerrainPopUpMenuItems>> buildTerrainPopUpMenuItems(
    {void Function(TerrainPopUpMenuItems item)? onItemPressed}) {
  return <PopupMenuEntry<TerrainPopUpMenuItems>>[
    buildMenuItem(
      item: TerrainPopUpMenuItems.checkInformation,
      name: engine.locale('checkInformation'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.createLocation,
      name: engine.locale('createLocation'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.bindMapObject,
      name: engine.locale('bindMapObject'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearMapObject,
      name: engine.locale('clearMapObject'),
      onItemPressed: onItemPressed,
    ),
    const PopupMenuDivider(height: 12.0),
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
      onItemPressed: onItemPressed,
    ),
    const PopupMenuDivider(height: 12.0),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearTerrainAnimation,
      name: engine.locale('clearTerrainAnimation'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearTerrainOverlaySprite,
      name: engine.locale('clearTerrainOverlaySprite'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: TerrainPopUpMenuItems.clearTerrainOverlayAnimation,
      name: engine.locale('clearTerrainOverlayAnimation'),
      onItemPressed: onItemPressed,
    ),
  ];
}

class WorldEditorOverlay extends StatefulWidget {
  WorldEditorOverlay({required this.args}) : super(key: UniqueKey());

  final Map<String, dynamic> args;

  @override
  State<WorldEditorOverlay> createState() => _WorldEditorOverlayState();
}

class _WorldEditorOverlayState extends State<WorldEditorOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Map<String, WorldMapScene> _maps = {};

  WorldMapScene get scene {
    assert(_maps.containsKey(GameData.currentWorldId));
    return _maps[GameData.currentWorldId]!;
  }

  Vector2? _menuPosition;

  bool _isLoading = false;
  bool _isLoaded = false;

  TileMapTerrain? _currentTerrain;
  dynamic _currentZone;
  dynamic _currentNation;
  dynamic _currentLocation;

  set currentTerrain(TileMapTerrain? terrain) {
    _currentTerrain = terrain;
    if (_currentTerrain == null) return;

    final zoneId = _currentTerrain!.zoneId;
    if (zoneId != null) {
      _currentZone =
          engine.hetu.invoke('getZoneById', positionalArgs: [zoneId]);
    } else {
      _currentZone = null;
    }

    final nationId = _currentTerrain!.nationId;
    if (nationId != null) {
      _currentNation =
          engine.hetu.invoke('getOrganizationById', positionalArgs: [nationId]);
    } else {
      _currentNation = null;
    }

    final String? locationId = _currentTerrain!.locationId;
    if (locationId != null) {
      _currentLocation =
          engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);
    } else {
      _currentLocation = null;
    }

    if (mounted) {
      context.read<SelectedTileState>().update(
            currentZoneData: _currentZone,
            currentNationData: _currentNation,
            currentLocationData: _currentLocation,
            currentTerrainObject: _currentTerrain,
          );
    }
  }

  // TODO:这里有一些复杂的算法来纠正地块的类型，具体见sandbox中的代码
  // 但地块类型初期实际上并不重要，可以暂时不是很完善。
  // void correctTerrainKind(TileMapTerrain tile) {
  //   final spriteIndex = tile.spriteIndex;
  //   switch (spriteIndex) {
  //     case kSpriteWater:
  //       tile.kind = kTerrainKindSea;
  //     case kSpriteLand:
  //       tile.kind = kTerrainKindPlain;
  //     case kSpriteForest:
  //       tile.kind = kTerrainKindForest;
  //     case kSpriteMountain:
  //       tile.kind = kTerrainKindMountain;
  //     default:
  //   }
  // }

  // void correctAllTerrainKind() {
  //   for (final tile in scene.map.terrains) {
  //     correctTerrainKind(tile);
  //   }
  // }

  Future<void> _refreshWorldmapCharacters() async {
    Iterable<dynamic> charsOnWorldMap = engine.hetu
        .invoke('getCharactersOnWorldMap', positionalArgs: [scene.map.id]);

    final charIds = charsOnWorldMap.map((value) => value['id']);

    final toBeRemoved = [];
    for (final obj in scene.map.movingObjects.values) {
      if (!charIds.contains(obj.id)) {
        toBeRemoved.add(obj.id);
      }
    }

    for (final id in toBeRemoved) {
      scene.map.movingObjects.remove(id);
    }

    for (final char in charsOnWorldMap) {
      final charId = char['id'];
      if (!scene.map.movingObjects.containsKey(charId)) {
        scene.map.loadMovingObject(char);
      } else {
        assert(char['worldPosition'] != null);
        final object = scene.map.movingObjects[charId]!;
        object.tilePosition = TilePosition(
            char['worldPosition']['left'], char['worldPosition']['top']);
        scene.map.refreshTileInfo(object);
      }
    }
  }

  void _mapTapHandler(int buttons, Vector2 position) {
    final tilePosition = scene.map.worldPosition2Tile(position);
    final toolItem = context.read<EditorToolState>().item;
    if (buttons == kPrimaryButton) {
      if (_menuPosition != null) {
        _menuPosition = null;
      } else {
        if (scene.map.trySelectTile(tilePosition.left, tilePosition.top)) {
          currentTerrain = scene.map.selectedTerrain;
          switch (toolItem) {
            case EditorToolItems.delete:
              _currentTerrain!.clearAllSprite();
              _currentTerrain!.kind = 'void';
            case EditorToolItems.nonInteractable:
              _currentTerrain!.isNonInteractable =
                  !_currentTerrain!.isNonInteractable;
            case EditorToolItems.sea:
              _currentTerrain!.spriteIndex = kSpriteWater;
              _currentTerrain?.kind = kTerrainKindSea;
            case EditorToolItems.plain:
              _currentTerrain!.spriteIndex = kSpriteLand;
              _currentTerrain?.kind = kTerrainKindPlain;
            case EditorToolItems.farmfield:
              _currentTerrain!.spriteIndex = kSpriteFarmField;
            case EditorToolItems.forest:
              _currentTerrain!.spriteIndex = kSpriteForest;
              _currentTerrain?.kind = kTerrainKindForest;
            case EditorToolItems.mountain:
              _currentTerrain!.spriteIndex = kSpriteMountain;
              _currentTerrain?.kind = kTerrainKindMountain;
            // case EditorToolItems.pond:
            //   _currentTerrain!.spriteIndex = kSpritePond;
            case EditorToolItems.fishTile:
              engine.hetu.invoke('setFishTile',
                  positionalArgs: [_currentTerrain!.data]);
            case EditorToolItems.stormTile:
              engine.hetu.invoke('setStormTile',
                  positionalArgs: [_currentTerrain!.data]);
            case EditorToolItems.spiritTile:
              engine.hetu.invoke('setSpiritTile',
                  positionalArgs: [_currentTerrain!.data]);
            case EditorToolItems.city:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {"spriteIndex": kSpriteCity},
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.portalArray:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {"spriteIndex": kSpriteArray},
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.dungeon:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {"spriteIndex": kSpriteCave},
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.dungeonStonePavedTile:
              _currentTerrain!.spriteIndex = kSpriteDungeonStonePavedTile;
              _currentTerrain!.kind = kTerrainKindPlain;
            case EditorToolItems.dungeonStoneGate:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {"spriteIndex": kSpriteDungeonStoneGate},
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.portal:
              final data = engine.hetu.interpreter.createStructfromJSON({
                "animation": {
                  "row": 6,
                  "to": 3,
                },
              });
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.glowingTile:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {"spriteIndex": kSpriteDungeonGlowingTile},
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.pressureTile:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {"spriteIndex": kSpriteDungeonUnpressedTile},
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.treasureBox:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {"spriteIndex": kSpriteTreasureBox},
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.none:
          }
        }
      }
    } else if (buttons == kSecondaryButton) {
      context.read<EditorToolState>().reset();
      if (tilePosition == scene.map.selectedTerrain?.tilePosition) {
        final screenPosition = scene.map
            .worldPosition2Screen(position, GameConfig.screenSize.toVector2());
        final popUpMenuPosition = RelativeRect.fromLTRB(
            screenPosition.x, screenPosition.y, screenPosition.x, 0.0);
        final items = buildTerrainPopUpMenuItems(onItemPressed: (item) {
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
                maxX: scene.map.tileMapWidth,
                maxY: scene.map.tileMapHeight,
                title: engine.locale('createLocation'),
                enableWorldId: false,
              ).then(((int, int, String?)? value) {
                if (value == null) return;
                showDialog(
                    context: context,
                    builder: (context) {
                      return LocationView(
                        mode: ViewPanelMode.create,
                        left: value.$1,
                        top: value.$2,
                      );
                    });
              });
            case TerrainPopUpMenuItems.bindMapObject:
              showDialog(
                context: context,
                builder: (context) => const InputStringDialog(),
              ).then((value) {
                if (value == null) return;
                _currentTerrain!.objectId = value;
              });
            case TerrainPopUpMenuItems.clearMapObject:
              _currentTerrain!.objectId = null;
            case TerrainPopUpMenuItems.empty:
              _currentTerrain!.kind = kTerrainKindEmpty;
            case TerrainPopUpMenuItems.plain:
              _currentTerrain!.kind = kTerrainKindPlain;
            case TerrainPopUpMenuItems.forest:
              _currentTerrain!.kind = kTerrainKindForest;
            case TerrainPopUpMenuItems.mountain:
              _currentTerrain!.kind = kTerrainKindMountain;
            case TerrainPopUpMenuItems.shore:
              _currentTerrain!.kind = kTerrainKindShore;
            case TerrainPopUpMenuItems.lake:
              _currentTerrain!.kind = kTerrainKindLake;
            case TerrainPopUpMenuItems.sea:
              _currentTerrain!.kind = kTerrainKindSea;
            case TerrainPopUpMenuItems.river:
              _currentTerrain!.kind = kTerrainKindRiver;
            case TerrainPopUpMenuItems.road:
              _currentTerrain!.kind = kTerrainKindRoad;
            case TerrainPopUpMenuItems.clearTerrainAnimation:
              _currentTerrain!.clearAnimation();
            case TerrainPopUpMenuItems.clearTerrainOverlaySprite:
              _currentTerrain!.clearOverlaySprite();
            case TerrainPopUpMenuItems.clearTerrainOverlayAnimation:
              _currentTerrain!.clearOverlayAnimation();
          }
          currentTerrain = scene.map.selectedTerrain;
        });
        showMenu(
          context: context,
          position: popUpMenuPosition,
          items: items,
        );
      }
    }
  }

  void closePopup() {
    setState(() {
      _menuPosition = null;
      scene.map.selectedTerrain = null;
    });
  }

  @override
  void initState() {
    super.initState();
    engine.hetu.invoke('build', positionalArgs: [context]);

    engine.hetu.interpreter.bindExternalFunction('setTerrainCaption', (
        {positionalArgs, namedArgs}) {
      if (!_isLoading) {
        scene.map.setTerrainCaption(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshTerrainSprite', (
        {positionalArgs, namedArgs}) {
      if (!_isLoading) {
        final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.tryLoadSprite();
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshTerrainOverlaySprite',
        ({positionalArgs, namedArgs}) {
      if (!_isLoading) {
        final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.tryLoadSprite(overlay: true);
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainAnimation', (
        {positionalArgs, namedArgs}) {
      if (!_isLoading) {
        final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearAnimation();
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlaySprite', (
        {positionalArgs, namedArgs}) {
      if (!_isLoading) {
        final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearOverlaySprite();
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlayAnimation',
        ({positionalArgs, namedArgs}) {
      if (!_isLoading) {
        final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearOverlayAnimation();
      }
    }, override: true);

    engine.addEventListener(
      GameEvents.mapLoaded,
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, args, scene) async {
          engine.hetu.invoke('showAllCaptions', namespace: 'debug');
          await _refreshWorldmapCharacters();
          setState(() {
            _isLoading = false;
          });
        },
      ),
    );

    engine.addEventListener(
      GameEvents.worldmapCharactersUpdated,
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, args, scene) async {
          _refreshWorldmapCharacters();
        },
      ),
    );
  }

  Future<bool> _prepareData() async {
    if (_isLoaded) return true;
    if (_isLoading) return false;
    _isLoading = true;

    if (!GameData.isGameCreated) {
      if (widget.args['method'] == 'load') {
        await GameData.loadGame(widget.args['path'], isEditorMode: true);
      } else {
        await GameData.newGame(widget.args['id'], widget.args['saveName']);
      }
    }
    await loadMap();
    _isLoaded = true;
    return true;
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    super.dispose();
  }

  void switchMap(String id) async {
    setState(() {
      GameData.currentWorldId = id;
    });
    if (!_maps.containsKey(id)) {
      await loadMap({
        'id': id,
        'method': 'load',
        'isEditorMode': true,
      });
    } else {
      GameData.currentWorldId = id;
      engine.hetu.invoke('switchWorld', positionalArgs: [id]);
      _refreshWorldmapCharacters();
    }
  }

  Future<void> loadMap([Map<String, dynamic>? args]) async {
    final id = args?['id'] ?? GameData.currentWorldId ?? widget.args['id'];
    if (engine.containsScene(id)) {
      setState(() {
        _isLoading = false;
      });
    }
    final scn = await engine.createScene(
      contructorKey: 'tilemap',
      sceneId: id,
      arg: args ?? widget.args,
    ) as WorldMapScene;
    // worldIds是set，所以这里添加重复值也不会有问题
    GameData.worldIds.add(scn.id);
    _maps[scn.id] = scn;
    GameData.currentWorldId = scn.id;
    scn.map.onTap = _mapTapHandler;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.sizeOf(context);

    return FutureBuilder(
      future: Future.delayed(
        const Duration(milliseconds: 100),
        () => _prepareData(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          if (snapshot.hasError) {
            throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
          }
          return const LoadingScreen();
        } else {
          WorldMapScene? currentMap = _maps[GameData.currentWorldId];

          if (currentMap == null) {
            return const LoadingScreen();
          }

          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                SceneWidget(scene: currentMap),
                if (_isLoading || (currentMap.isLoading)) const LoadingScreen(),
                Positioned(
                  right: 0,
                  top: 0,
                  child: WorldEditorDropMenu(
                    onSelected: (WorldEditorDropMenuItems item) async {
                      switch (item) {
                        case WorldEditorDropMenuItems.addWorld:
                          showDialog(
                            context: context,
                            builder: (context) => const CreateBlankMapDialog(
                                isCreatingNewGame: false),
                          ).then((value) {
                            if (value == null) return;
                            loadMap(value);
                          });
                        case WorldEditorDropMenuItems.switchWorld:
                          showDialog(
                            context: context,
                            builder: (context) => SelectDialog(
                                selections: {
                                  for (var element in GameData.worldIds)
                                    element: element
                                },
                                selectedValue: GameData.worldIds.firstWhere(
                                    (element) =>
                                        element != GameData.currentWorldId)),
                          ).then((value) {
                            if (value == null) return;
                            switchMap(value);
                          });
                        case WorldEditorDropMenuItems.expandWorld:
                          showDialog<(int, int, String)>(
                                  context: context,
                                  builder: (context) =>
                                      const ExpandWorldDialog())
                              .then(((int, int, String)? value) {
                            if (value == null) return;
                            engine.hetu.invoke('expandCurrentWorldBySize',
                                positionalArgs: [value.$1, value.$2, value.$3]);
                            scene.map.updateData();
                          });
                        case WorldEditorDropMenuItems.save:
                          String worldId =
                              engine.hetu.invoke('getCurrentWorldId');
                          String? saveName = engine.hetu.invoke('getSaveName');
                          context
                              .read<GameSavesState>()
                              .saveGame(worldId, saveName)
                              .then((saveInfo) {
                            GameDialog.show(
                              context: context,
                              dialogData: {
                                'lines': [
                                  engine.locale('savedSuccessfully',
                                      interpolations: [saveInfo.savePath]),
                                ],
                              },
                            );
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
                            engine.hetu.invoke('setSaveName',
                                positionalArgs: [saveName]);
                            String worldId =
                                engine.hetu.invoke('getCurrentWorldId');
                            context
                                .read<GameSavesState>()
                                .saveGame(worldId, saveName)
                                .then((saveInfo) {
                              GameDialog.show(
                                context: context,
                                dialogData: {
                                  'lines': [
                                    engine.locale('savedSuccessfully',
                                        interpolations: [saveInfo.savePath]),
                                  ],
                                },
                              );
                            });
                          });
                        case WorldEditorDropMenuItems.viewNone:
                          scene.map.colorMode = kColorModeNone;
                        case WorldEditorDropMenuItems.viewZones:
                          scene.map.colorMode = kColorModeZone;
                        case WorldEditorDropMenuItems.viewOrganizations:
                          scene.map.colorMode = kColorModeOrganization;
                        case WorldEditorDropMenuItems.console:
                          showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                Console(engine: engine),
                          ).then((_) => setState(() {}));
                        case WorldEditorDropMenuItems.exit:
                          context.read<SelectedTileState>().clear();
                          context.read<EditorToolState>().reset();
                          for (final scn in _maps.values) {
                            scn.leave(clearCache: true);
                          }
                          // engine.hetu.invoke('resetGame');
                          Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                Positioned(
                  child: EntityListPanel(
                    size: Size(320, screenSize.height),
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
                    child: Toolbox(
                      onItemClicked: (item) {},
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
