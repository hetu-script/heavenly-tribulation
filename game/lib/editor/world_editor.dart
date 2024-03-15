import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:hetu_script/hetu_script.dart';
// import 'package:hetu_script/values.dart';
// import 'package:flame/flame.dart';
// import 'package:flame/sprite.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/console.dart';
import 'package:provider/provider.dart';
import 'package:samsara/event.dart';

// import '../../../event/ui.dart';
// import '../../../ui/view/information/information.dart';
// import '../../../shared/constants.dart';
import '../config.dart';
import '../scene/world/world.dart';
import 'components/drop_menu.dart';
// import '../../../ui/view/location/location.dart';
// import '../common.dart';
// import 'location/location.dart';
import '../state/tile_info.dart';
import '../scene/world/common.dart';
import 'components/toolbox.dart';
import '../state/saves.dart';
import '../dialog/game_dialog/game_dialog.dart';
import 'components/entity_list.dart';
import 'components/tile_info.dart';
import '../scene/menu_item_builder.dart';
import 'components/tile_detail.dart';
import '../view/location/location.dart';
import '../dialog/input_world_location.dart';
import '../view/common.dart';
import '../events.dart';
import '../state/editor_tool.dart';
import '../dialog/input_string.dart';

enum TerrainPopUpMenuItems {
  checkInformation,
  createLocation,
  setInteractable,
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
    buildMenuItem(
      item: TerrainPopUpMenuItems.setInteractable,
      name: engine.locale('setInteractable'),
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

  late WorldMapScene _scene;

  Vector2? _menuPosition;

  bool _isDisposing = false;
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
      context.read<SelectedTileState>().updateTerrain(
            currentZoneData: _currentZone,
            currentNationData: _currentNation,
            currentLocationData: _currentLocation,
            currentTerrainObject: _currentTerrain,
          );
    }
  }

  // TODO:这里有一些复杂的算法来纠正地块的类型，具体见sandbox中的代码
  // 但地块类型初期实际上并不重要，可以暂时不是很完善。
  void correctTerrainKind(TileMapTerrain tile) {
    final spriteIndex = tile.spriteIndex;
    switch (spriteIndex) {
      case kSpriteWater:
        tile.kind = kTerrainKindSea;
      case kSpriteLand:
        tile.kind = kTerrainKindPlain;
      case kSpriteForest:
        tile.kind = kTerrainKindForest;
      case kSpriteMountain:
        tile.kind = kTerrainKindMountain;
      default:
    }
  }

  void correctAllTerrainKind() {
    for (final tile in _scene.map.terrains) {
      correctTerrainKind(tile);
    }
  }

  Future<void> _refreshWorldmapCharacters() async {
    Iterable<dynamic> charsOnWorldMap = engine.hetu
        .invoke('getCharactersOnWorldMap', positionalArgs: [_scene.map.id]);

    final charIds = charsOnWorldMap.map((value) => value['id']);

    final toBeRemoved = [];
    for (final obj in _scene.map.movingObjects.values) {
      if (!charIds.contains(obj.id)) {
        toBeRemoved.add(obj.id);
      }
    }

    for (final id in toBeRemoved) {
      _scene.map.movingObjects.remove(id);
    }

    for (final char in charsOnWorldMap) {
      final charId = char['id'];
      if (!_scene.map.movingObjects.containsKey(charId)) {
        _scene.map.loadMovingObject(char);
      } else {
        assert(char['worldPosition'] != null);
        final object = _scene.map.movingObjects[charId]!;
        object.tilePosition = TilePosition(
            char['worldPosition']['left'], char['worldPosition']['top']);
        _scene.map.refreshTileInfo(object);
      }
    }
  }

  void _mapTapHandler(int buttons, Vector2 position) {
    final tilePosition = _scene.map.worldPosition2Tile(position);
    final toolItem = context.read<EditorToolState>().item;
    if (buttons == kPrimaryButton) {
      if (_menuPosition != null) {
        _menuPosition = null;
      } else {
        if (_scene.map.trySelectTile(tilePosition.left, tilePosition.top)) {
          currentTerrain = _scene.map.selectedTerrain;
          switch (toolItem) {
            case EditorToolItems.delete:
              _currentTerrain!.clearAllSprite();
              _currentTerrain!.kind = 'void';
            case EditorToolItems.sea:
              _currentTerrain!.spriteIndex = kSpriteWater;
            case EditorToolItems.plain:
              _currentTerrain!.spriteIndex = kSpriteLand;
            case EditorToolItems.forest:
              _currentTerrain!.spriteIndex = kSpriteForest;
            case EditorToolItems.mountain:
              _currentTerrain!.spriteIndex = kSpriteMountain;
            case EditorToolItems.shelf:
              _currentTerrain!.spriteIndex = kSpriteShelf;
            case EditorToolItems.farmfield:
              _currentTerrain!.spriteIndex = kSpriteFarmField;
            // case EditorToolItems.pond:
            //   _currentTerrain!.spriteIndex = kSpritePond;
            case EditorToolItems.city:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {"spriteIndex": kSpriteCity},
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.fishZone:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {
                  'animation': {'row': 3}
                },
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.stormZone:
              final data = engine.hetu.interpreter.createStructfromJSON(
                {
                  'animation': {
                    'row': 4,
                    'loop': true,
                  },
                },
              );
              _currentTerrain!.overlaySprite = data;
            case EditorToolItems.none:
          }
          correctTerrainKind(_currentTerrain!);
        }
      }
    } else if (buttons == kSecondaryButton) {
      if (toolItem != EditorToolItems.none) {
        context.read<EditorToolState>().reset();
      } else {
        context.read<EditorToolState>().reset();
        if (_scene.map.trySelectTile(tilePosition.left, tilePosition.top)) {
          currentTerrain = _scene.map.selectedTerrain;
          final screenPosition = _scene.map.worldPosition2Screen(
              position, GameConfig.screenSize.toVector2());
          final popUpMenuPosition = RelativeRect.fromLTRB(
              screenPosition.x, screenPosition.y, screenPosition.x, 0.0);
          final items = buildTerrainPopUpMenuItems(onItemPressed: (item) {
            switch (item) {
              case TerrainPopUpMenuItems.checkInformation:
                showDialog(
                    context: context,
                    builder: (context) => const TileDetailPanel());
              case TerrainPopUpMenuItems.createLocation:
                InputWorldLocationDialog.show(
                  context: context,
                  defaultX: tilePosition.left,
                  defaultY: tilePosition.top,
                  maxX: _scene.map.tileMapWidth,
                  maxY: _scene.map.tileMapHeight,
                  title: engine.locale('createLocation'),
                ).then(((int, int)? value) {
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
              case TerrainPopUpMenuItems.setInteractable:
                _currentTerrain!.isNonInteractable =
                    !_currentTerrain!.isNonInteractable;
            }
          });
          showMenu(
            context: context,
            position: popUpMenuPosition,
            items: items,
          );
        }
      }
    }
  }

  void closePopup() {
    setState(() {
      _menuPosition = null;
      _scene.map.selectedTerrain = null;
    });
  }

  @override
  void initState() {
    super.initState();
    engine.hetu.invoke('build', positionalArgs: [context]);

    engine.hetu.interpreter.bindExternalFunction('setTerrainCaption', (
        {positionalArgs, namedArgs}) {
      _scene.map.setTerrainCaption(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshTerrainSprite', (
        {positionalArgs, namedArgs}) {
      final tile = _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.tryLoadSprite();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshTerrainOverlaySprite',
        ({positionalArgs, namedArgs}) {
      if (_isLoaded) {
        final tile =
            _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.tryLoadSprite(overlay: true);
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainAnimation', (
        {positionalArgs, namedArgs}) {
      if (_isLoaded) {
        final tile =
            _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearAnimation();
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlaySprite', (
        {positionalArgs, namedArgs}) {
      if (_isLoaded) {
        final tile =
            _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearOverlaySprite();
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlayAnimation',
        ({positionalArgs, namedArgs}) {
      if (_isLoaded) {
        final tile =
            _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
        tile?.clearOverlayAnimation();
      }
    }, override: true);

    engine.addEventListener(
      GameEvents.mapLoaded,
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, args, scene) async {
          engine.hetu.invoke('showAllCaptions', namespace: 'debug');
          _refreshWorldmapCharacters();
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

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    _scene.detach();
    super.dispose();
  }

  Future<Scene?> _getScene(Map<String, dynamic> args) async {
    if (_isDisposing) return null;
    final scene = await engine.createScene(
      contructorKey: 'worldmap',
      sceneId: args['id'],
      arg: args,
    ) as WorldMapScene;

    scene.map.onDragUpdate =
        (int buttons, Vector2 dragPosition, Vector2 dragOffset) {
      if (buttons == kPrimaryButton) {
        scene.camera.moveBy(-dragOffset / scene.camera.viewfinder.zoom);
      }
    };

    scene.map.onMouseHover = (Vector2 position) {
      final tilePosition = scene.map.worldPosition2Tile(position);
      scene.map.hoverTerrain = scene.map.getTerrainByPosition(tilePosition);
    };

    scene.map.onTap = (int buttons, Vector2 position) {
      // final tilePosition = scene.map.worldPosition2Tile(position);

      // if (kDebugMode) {
      //   print('tilemap tapped at: $tilePosition');
      // }
    };

    scene.map.onDoubleTap = (int buttons, Vector2 position) {
      // final tilePosition = map.worldPosition2Tile(position);

      // if (kDebugMode) {
      // print('tilemap double tapped at: $tilePosition');
      // }
    };

    scene.map.onDragUpdate =
        (int buttons, Vector2 dragPosition, Vector2 dragOffset) {
      if (buttons == kPrimaryButton) {
        scene.camera.moveBy(-dragOffset / scene.camera.viewfinder.zoom);
      }
    };

    scene.map.onMouseHover = (Vector2 position) {
      final tilePosition = scene.map.worldPosition2Tile(position);
      scene.map.hoverTerrain = scene.map.getTerrainByPosition(tilePosition);
    };

    scene.map.onTap = _mapTapHandler;

    _isLoaded = true;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.sizeOf(context);

    // ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return _isDisposing
        ? LoadingScreen(text: engine.locale('loading'))
        : FutureBuilder(
            // 不知道为啥，这里必须用这种写法才能进入载入界面，否则一定会卡住
            future: Future.delayed(
              const Duration(milliseconds: 100),
              () => _getScene(widget.args),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                if (snapshot.hasError) {
                  throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
                }
                return LoadingScreen(
                  text: engine.locale('loading'),
                  showClose: snapshot.hasError,
                );
              } else {
                _scene = snapshot.data as WorldMapScene;
                if (_scene.isAttached) {
                  _scene.detach();
                }

                return Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      SceneWidget(scene: _scene),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: WorldEditorDropMenu(
                          onSelected: (WorldEditorDropMenuItems item) async {
                            switch (item) {
                              case WorldEditorDropMenuItems.expandWorld:
                                InputWorldLocationDialog.show(
                                  context: context,
                                  defaultX: 10,
                                  defaultY: 10,
                                ).then(((int, int)? value) {
                                  if (value == null) return;
                                  engine.hetu.invoke('expandCurrentWorldBySize',
                                      positionalArgs: [value.$1, value.$2]);
                                  _scene.map.updateData();
                                });
                              case WorldEditorDropMenuItems.save:
                                String worldId =
                                    engine.hetu.invoke('getWorldId');
                                String? saveName =
                                    engine.hetu.invoke('getSaveName');
                                context
                                    .read<Saves>()
                                    .saveGame(worldId, saveName)
                                    .then((saveInfo) {
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
                                      engine.hetu.invoke('getWorldId');
                                  context
                                      .read<Saves>()
                                      .saveGame(worldId, saveName)
                                      .then((saveInfo) {
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
                                  });
                                });
                              case WorldEditorDropMenuItems.console:
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      Console(engine: engine),
                                ).then((_) => setState(() {}));
                              case WorldEditorDropMenuItems.exit:
                                context
                                    .read<SelectedTileState>()
                                    .clearTerrain();
                                context.read<EditorToolState>().reset();
                                _scene.leave(clearCache: true);
                                _isDisposing = true;
                                engine.hetu.invoke('resetGame');
                                Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                      Positioned(
                        child: EntityListPanel(
                          size: Size(300, screenSize.height),
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
