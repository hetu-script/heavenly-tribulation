import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:hetu_script/hetu_script.dart';
// import 'package:hetu_script/values.dart';
// import 'package:flame/flame.dart';
// import 'package:flame/sprite.dart';
import 'package:provider/provider.dart';
import 'package:samsara/event.dart';

import 'widgets/expand_world_dialog.dart';
import '../data.dart';
// import '../../../event/ui.dart';
// import '../../../ui/view/information/information.dart';
// import '../../../shared/constants.dart';
import '../engine.dart';
import '../scene/world/world.dart';
import 'widgets/drop_menu.dart';
// import '../../../ui/view/location/location.dart';
// import '../common.dart';
// import 'location/location.dart';
import '../state/selected_tile.dart';
import '../scene/common.dart';
import 'widgets/toolbox.dart';
import '../state/game_save.dart';
import '../game_dialog/game_dialog/game_dialog.dart';
import 'widgets/entity_list.dart';
import 'widgets/tile_info.dart';
import '../view/menu_item_builder.dart';
import 'widgets/tile_detail.dart';
import '../view/location/location.dart';
import '../game_dialog/input_world_position.dart';
import '../view/common.dart';
import '../scene/events.dart';
import '../state/editor_tool.dart';
import '../game_dialog/input_string.dart';
import '../scene/loading_screen.dart';
import '../mainmenu/create_blank_map.dart';
import '../game_dialog/select_menu_dialog.dart';
// import '../common.dart';

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
  clearTerrainAnimation,
  clearTerrainOverlaySprite,
  clearTerrainOverlayAnimation,
}

List<PopupMenuEntry<TerrainPopUpMenuItems>> buildTerrainPopUpMenuItems(
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

/// {
///   'id': id,
///   'method': 'load',
///   'savePath': info.savePath,
///   'isEditorMode': true,
/// }
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

  final _focusNode = FocusNode();
  // late final FocusAttachment _nodeAttachment;

  late WorldMapScene scene;

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
      scene.map.removeMovingObject(id);
    }

    for (final char in charsOnWorldMap) {
      final charId = char['id'];
      if (!scene.map.movingObjects.containsKey(charId)) {
        scene.map.loadMovingObjectFromData(char);
      } else {
        assert(char['worldPosition'] != null);
        final object = scene.map.movingObjects[charId]!;
        object.tilePosition = TilePosition(
            char['worldPosition']['left'], char['worldPosition']['top']);
        scene.map.refreshTileInfo(object);
      }
    }
  }

  bool _dragged = false;

  void _onMapTapDown(int buttons, Vector2 position) {
    _dragged = false;

    final tilePosition = scene.map.worldPosition2Tile(position);
    if (tilePosition != scene.map.selectedTerrain?.tilePosition) {
      if (scene.map.trySelectTile(tilePosition.left, tilePosition.top)) {
        currentTerrain = scene.map.selectedTerrain;
      }
    }
  }

  void _onMapTapUp(int buttons, Vector2 position) {
    final tilePosition = scene.map.worldPosition2Tile(position);
    if (buttons == kPrimaryButton) {
      // print('zoom: ${scene.camera.zoom}');
      // print('position: $position');
      // print('cemara positon: ${scene.camera.viewfinder.position}');
      // print((position - scene.camera.viewfinder.position) *
      //         scene.camera.viewfinder.zoom +
      //     scene.size / 2);
      // print(scene.map.worldPosition2Screen(position));
      if (tilePosition == scene.map.selectedTerrain?.tilePosition) {
        final toolId = context.read<EditorToolState>().selectedId;
        switch (toolId) {
          case 'delete':
            _currentTerrain!.clearAllSprite();
            _currentTerrain!.kind = 'void';
          case 'nonInteractable':
            _currentTerrain!.isNonEnterable = !_currentTerrain!.isNonEnterable;
          default:
            final toolItemData = GameData.editorToolItemsData[toolId];
            if (toolItemData != null) {
              final toolType = toolItemData['type'];
              switch (toolType) {
                case 'terrain':
                  _currentTerrain!.spriteIndex =
                      toolItemData['spriteIndex'] as int?;
                  _currentTerrain!.kind = toolItemData['kind'] as String?;
                case 'script':
                  engine.hetu.invoke(toolItemData['invoke'] as String,
                      positionalArgs: [_currentTerrain!.data]);
                case 'overlaySprite':
                  _currentTerrain!.overlaySprite = engine.hetu.interpreter
                      .createStructfromJSON(toolItemData['overlay'] as Map);
              }
            }
        }
      }
    } else if (buttons == kSecondaryButton) {
      if (_dragged == true) {
        return;
      }
      if (tilePosition == scene.map.selectedTerrain?.tilePosition) {
        final screenPosition = scene.map.worldPosition2Screen(position);
        final popUpMenuPosition = RelativeRect.fromLTRB(
            screenPosition.x,
            screenPosition.y + scene.map.gridSize.y * scene.camera.zoom,
            screenPosition.x + scene.map.gridSize.x * scene.camera.zoom,
            0.0);
        final items = buildTerrainPopUpMenuItems(onSelectedItem: (item) {
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
                if (!mounted || value == null) return;
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
            case TerrainPopUpMenuItems.bindObject:
              showDialog(
                context: context,
                builder: (context) => const InputStringDialog(),
              ).then((value) {
                if (value == null) return;
                _currentTerrain!.objectId = value;
                _currentTerrain!.caption = value;
              });
            case TerrainPopUpMenuItems.clearObject:
              _currentTerrain!.objectId = null;
              _currentTerrain!.caption = null;
            case TerrainPopUpMenuItems.empty:
              _currentTerrain!.kind = kTerrainKindVoid;
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

  @override
  void initState() {
    super.initState();

    engine.hetu.interpreter.bindExternalFunction('setTerrainCaption', (
        {positionalArgs, namedArgs}) {
      if (_isLoaded) {
        scene.map.setTerrainCaption(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshTerrainSprite', (
        {positionalArgs, namedArgs}) {
      if (_isLoaded) {
        final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.tryLoadSprite();
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshTerrainOverlaySprite',
        ({positionalArgs, namedArgs}) {
      final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.tryLoadSprite(overlay: true);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainAnimation', (
        {positionalArgs, namedArgs}) {
      final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearAnimation();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlaySprite', (
        {positionalArgs, namedArgs}) {
      final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearOverlaySprite();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlayAnimation',
        ({positionalArgs, namedArgs}) {
      final tile = scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearOverlayAnimation();
    }, override: true);

    engine.addEventListener(
      GameEvents.mapLoaded,
      EventHandler(
        widgetKey: widget.key!,
        callback: (eventId, args, scene) async {
          engine.hetu.invoke('refreshAllCaptions', namespace: 'debug');
          await _refreshWorldmapCharacters();
          setState(() {});
        },
      ),
    );

    engine.addEventListener(
      GameEvents.worldmapCharactersUpdated,
      EventHandler(
        widgetKey: widget.key!,
        callback: (eventId, args, scene) async {
          _refreshWorldmapCharacters();
        },
      ),
    );

    // _nodeAttachment =
    //     _toolBoxfocusNode.attach(context, on: (node, event) {
    //   if (event.physicalKey == PhysicalKeyboardKey.escape) {
    //     context.read<EditorToolState>().reset();
    //   }

    //   return KeyEventResult.handled;
    // });

    // _toolBoxfocusNode.requestFocus();
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> loadMap([Map<String, dynamic>? args]) async {
    if (_isLoading) return false;
    if (args == null) {
      if (_isLoaded) return true;
    }
    _isLoading = true;

    args ??= widget.args;

    // 创建或读取游戏存档
    if (!GameData.isGameCreated) {
      if (args['method'] == 'load') {
        await GameData.loadGame(args['savePath'], isEditorMode: true);
      } else {
        await GameData.newGame(args['id'], widget.args['saveName']);
      }
    }

    final id = args['id'];

    if (engine.containsScene(id)) {
      scene = engine.switchScene(id)!;
    } else {
      scene = await engine.createScene(
        contructorKey: kSceneTilemap,
        sceneId: id,
        arg: args,
      ) as WorldMapScene;
      scene.map.onDragUpdate = (int buttons, Vector2 offset) {
        if (buttons == kSecondaryButton) {
          _dragged = true;
          scene.camera.moveBy(-offset);
        }
      };
      scene.map.onTapDown = _onMapTapDown;
      scene.map.onTapUp = _onMapTapUp;
    }

    GameData.currentWorldId = scene.id;

    _refreshWorldmapCharacters();

    setState(() {
      _isLoaded = true;
      _isLoading = false;
    });

    return _isLoaded;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // _nodeAttachment.reparent();

    final screenSize = MediaQuery.sizeOf(context);

    return FutureBuilder(
      future: Future.delayed(
        const Duration(milliseconds: 200),
        () => loadMap(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          if (snapshot.hasError) {
            throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
          }
          return const LoadingScreen();
        } else {
          _focusNode.requestFocus();
          return KeyboardListener(
            autofocus: true,
            focusNode: _focusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                if (kDebugMode) {
                  print('keydown: ${event.logicalKey.keyLabel}');
                }
                switch (event.logicalKey) {
                  case LogicalKeyboardKey.space:
                    if (_isLoaded) {
                      scene.camera.zoom = 2.0;
                    }
                  case LogicalKeyboardKey.escape:
                    context.read<EditorToolState>().reset();
                  default:
                }
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  SceneWidget(scene: scene),
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
                              builder: (context) => SelectMenuDialog(
                                  selections: {
                                    for (var element in GameData.worldIds)
                                      element: element
                                  },
                                  selectedValue: GameData.worldIds.firstWhere(
                                      (element) =>
                                          element != GameData.currentWorldId)),
                            ).then((value) {
                              if (value == null) return;
                              loadMap({
                                'id': value,
                                'method': 'load',
                                'isEditorMode': true,
                              });
                            });
                          case WorldEditorDropMenuItems.expandWorld:
                            showDialog<(int, int, String)>(
                                    context: context,
                                    builder: (context) =>
                                        const ExpandWorldDialog())
                                .then(((int, int, String)? value) {
                              if (value == null) return;
                              engine.hetu.invoke('expandCurrentWorldBySize',
                                  positionalArgs: [
                                    value.$1,
                                    value.$2,
                                    value.$3
                                  ]);
                              scene.map.updateData();
                            });
                          case WorldEditorDropMenuItems.save:
                            String worldId =
                                engine.hetu.invoke('getCurrentWorldId');
                            String? saveName =
                                engine.hetu.invoke('getSaveName');
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
                              engine.hetu.invoke('setSaveName',
                                  positionalArgs: [saveName]);
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
                                              interpolations: [
                                                saveInfo.savePath
                                              ]),
                                        ],
                                      },
                                    );
                                  }
                                });
                              }
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
                            engine.clearAllCache();
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
                        onToolClicked: (item) {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
