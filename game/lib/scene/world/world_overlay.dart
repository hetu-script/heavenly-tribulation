import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:samsara/tilemap.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
// import 'package:flame/flame.dart';
// import 'package:flame/sprite.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/console.dart';
import 'package:provider/provider.dart';

import '../../../dialog/game_dialog/game_dialog.dart';
import '../quest_info.dart';
// import '../../../event/ui.dart';
import '../../view/world_infomation/world_infomation.dart';
import 'popup.dart';
// import '../../../shared/constants.dart';
import '../history_panel.dart';
import '../../config.dart';
import 'world.dart';
import '../hero_info.dart';
import 'drop_menu.dart';
// import '../../../ui/view/location/location.dart';
import '../../dialog/character_select_dialog.dart';
// import '../../../dialog/game_over.dart';
// import '../common.dart';
import 'location/location_site.dart';
import '../../state/states.dart';
import 'common.dart';
import '../../events.dart';
import '../../common.dart';
import 'npc_list.dart';
import '../../dialog/input_string.dart';
import '../../extensions.dart';

class WorldOverlay extends StatefulWidget {
  WorldOverlay({required this.args}) : super(key: UniqueKey());

  final Map<String, dynamic> args;

  @override
  State<WorldOverlay> createState() => _WorldOverlayState();
}

class _WorldOverlayState extends State<WorldOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late WorldMapScene _scene;

  bool _isLoaded = false;

  HTStruct? _heroData, _questData;

  Vector2? _menuPosition;

  bool _isDisposing = false;

  TileMapTerrain? _currentTerrain;
  dynamic _currentZone;
  dynamic _currentNation;
  dynamic _currentLocation;
  Iterable<dynamic> _npcsInHeroPosition = [];

  bool _playerFreezed = false;
  set playerFreezed(bool value) {
    _playerFreezed = _scene.map.autoUpdateMovingObject = value;

    if (!value) {
      setState(() {});
    }
  }

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

  Future<void> _refreshNpcsInHeroWorldMapPosition() async {
    _npcsInHeroPosition =
        engine.hetu.invoke('getNpcsInWorldMapPosition', positionalArgs: [
      _heroData?['worldPosition']['left'],
      _heroData?['worldPosition']['top'],
    ]);

    if (mounted) {
      context.read<CurrentNpcList>().updated(_npcsInHeroPosition);
    }
  }

  Future<void> _refreshNpcsInHeroLocation() async {
    final npcsInHeroLocation =
        engine.hetu.invoke('getNpcsInLocation', positionalArgs: [
      _heroData?['locationId'],
    ]);

    if (mounted) {
      context.read<CurrentNpcList>().updated(npcsInHeroLocation);
    }
  }

  Future<void> _refreshNpcsInHeroSite() async {
    final npcsInHeroSite = engine.hetu.invoke('getNpcsInSite', positionalArgs: [
      _heroData?['siteId'],
    ]);

    if (mounted) {
      context.read<CurrentNpcList>().updated(npcsInHeroSite);
    }
  }

  Future<void> _refreshMap() async {
    Iterable<dynamic> npcsOnWorldMap = engine.hetu
        .invoke('getNpcsOnWorldMap', positionalArgs: [_scene.map.id]);

    final charIds = npcsOnWorldMap.map((value) => value['id']);

    final toBeRemoved = [];
    for (final obj in _scene.map.movingObjects.values) {
      if (!charIds.contains(obj.id)) {
        toBeRemoved.add(obj.id);
      }
    }

    for (final id in toBeRemoved) {
      _scene.map.movingObjects.remove(id);
    }

    for (final char in npcsOnWorldMap) {
      final charId = char['id'];
      if (!_scene.map.movingObjects.containsKey(charId)) {
        _scene.map.loadMovingObject(char, (left, top) {
          engine.hetu.invoke('setCharacterWorldPosition',
              positionalArgs: [char, left, top]);
        });
      } else {
        assert(char['worldPosition'] != null);
        final object = _scene.map.movingObjects[charId]!;
        object.tilePosition = TilePosition(
            char['worldPosition']['left'], char['worldPosition']['top']);
        _scene.map.refreshTileInfo(object);
      }
    }

    _refreshNpcsInHeroWorldMapPosition();

    if (mounted) {
      context.read<HistoryState>().update();
    }
  }

  Future<void> _onHeroMoved(int left, int top) async {
    final blocked = engine.hetu
        .invoke('onAfterHeroMoveOnWorldMap', positionalArgs: [left, top]);
    if (blocked != null) {
      // 如果blocked有值，无论真假，都会停止移动
      if (blocked) {
        // 让英雄返回上一格
        _scene.map.cancelObjectMoving(_scene.map.hero!);
        return;
      } else {
        // 让英雄停在这一格
        _scene.map.hero!.isMovingCanceled = true;
      }
    }

    final lightedAreaSize = _heroData!['stats']['lightedArea'];

    _scene.map.lightUpAroundTile(_scene.map.hero!.tilePosition,
        size: lightedAreaSize);

    engine.hetu.invoke('setHeroWorldPosition', positionalArgs: [left, top]);

    currentTerrain = _scene.map.getTerrainAtHero();

    engine.hetu.invoke('updateGame');

    await _refreshMap();

    // 如果英雄所在格子只有一个npc，则默认直接和该npc互动
    if (_npcsInHeroPosition.length == 1) {
      final npcId = _npcsInHeroPosition.first['id'];
      engine.hetu.invoke('onInteractCharacter', positionalArgs: [npcId]);
    }
  }

  Future<void> _interactTerrain(TileMapTerrain terrain) async {
    await engine.hetu
        .invoke('onInteractTerrain', positionalArgs: [terrain.data]);
  }

  Future<void> _enterLocation(String locationId) async {
    final locationData =
        engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);

    await engine.hetu
        .invoke('onBeforeHeroEnterLocation', positionalArgs: [locationData]);

    // if (!context.mounted) return;
    if (locationData['isDiscovered'] == true) {
      if (mounted) {
        _scene.bgm.pause();
        final Iterable<dynamic> npcs = engine.hetu
            .invoke('getNpcsInLocation', positionalArgs: [locationData['id']]);
        context.read<CurrentNpcList>().updated(npcs);

        await showDialog(
          context: context,
          builder: (context) => LocationSiteSceneOverlay(
            key: UniqueKey(),
            terrainObject: _currentTerrain,
            locationData: locationData,
          ),
        );

        _scene.bgm.resume();

        _refreshNpcsInHeroWorldMapPosition();
      }
    }
  }

  List? _calculateRoute(
      {required int fromX,
      required int fromY,
      required int toX,
      required int toY}) {
    final start = engine.hetu.invoke('getTerrainByWorldPosition',
        positionalArgs: [fromX, fromY, _scene.worldData]);
    final end = engine.hetu.invoke('getTerrainByWorldPosition',
        positionalArgs: [toX, toY, _scene.worldData]);
    List? calculatedRoute = engine.hetu.invoke('calculateRoute',
        positionalArgs: [start, end, _scene.worldData]);
    return calculatedRoute;
  }

  void _onMapTapped(int buttons, Vector2 position) {
    if (_playerFreezed) return;

    final tilePosition = _scene.map.worldPosition2Tile(position);
    final hero = _scene.map.hero;
    if (hero == null) return;
    if (_menuPosition != null) {
      setState(() {
        _menuPosition = null;
      });
    } else {
      if (buttons & kPrimaryButton == kPrimaryButton) {
        if (tilePosition == _scene.map.selectedTerrain?.tilePosition) {
          if (_scene.map.hero?.isMoving ?? false) return;

          if (hero.isMoving) return;
          final terrain = _scene.map.selectedTerrain;
          if (terrain!.terrainKind == TileMapTerrainKind.empty) return;
          if (terrain.tilePosition != hero.tilePosition) {
            final calculatedRoute = _calculateRoute(
                fromX: hero.left,
                fromY: hero.top,
                toX: terrain.left,
                toY: terrain.top);
            if (calculatedRoute != null) {
              final route = List<int>.from(calculatedRoute);
              if (terrain.locationId != null) {
                _scene.map.moveObjectToTilePositionByRoute(
                  _scene.map.hero!,
                  route,
                  onDestinationCallback: () =>
                      _enterLocation(terrain.locationId!),
                );
              } else {
                _scene.map
                    .moveObjectToTilePositionByRoute(_scene.map.hero!, route);
              }
            }
          } else {
            if (terrain.locationId != null) {
              _enterLocation(terrain.locationId!);
            }
          }
        } else {
          _scene.map.trySelectTile(tilePosition.left, tilePosition.top);
        }
      } else if (buttons & kSecondaryButton == kSecondaryButton) {
        if (_scene.map.trySelectTile(tilePosition.left, tilePosition.top)) {
          setState(() {
            _menuPosition = _scene.map.tilePosition2TileCenterInScreen(
                tilePosition.left, tilePosition.top);
          });
        }
      }
    }
  }

  Future<void> _onMapLoaded() async {
    final isNewGame = engine.hetu.fetch('isNewGame');
    _heroData = engine.hetu.invoke('getHero');
    if (mounted) {
      context.read<SelectedTileState>().updateHero(_heroData);
    }
    if (isNewGame ?? false) {
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
        final heroHome = engine.hetu.invoke('getHeroHomeLocation');
        engine.hetu.invoke('discoverLocation', positionalArgs: [heroHome]);
        _heroData = engine.hetu.invoke('getHero');
        if (mounted) {
          context.read<SelectedTileState>().updateHero(_heroData);
        }
      }

      for (final id in GameConfig.modules.keys) {
        if (GameConfig.modules[id]?['enabled'] == true) {
          final moduleConfig = {
            'version': {
              'major': kGameVersionMajor,
              'minor': kGameVersionMinor,
              'build': kGameVersionBuild,
            }
          };
          engine.hetu
              .invoke('init', module: id, positionalArgs: [moduleConfig]);
        }
      }

      engine.hetu.invoke('onNewGame');
    }

    assert(_heroData != null);
    await _scene.map.loadHero(_heroData, _onHeroMoved);
    currentTerrain = _scene.map.getTerrainAtHero();

    await _refreshMap();

    if (mounted) {
      context.read<HistoryState>().update();
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

    // engine.hetu.interpreter.bindExternalFunction('showWorldMapGameOver', (
    //     {positionalArgs, namedArgs}) {
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) => const GameOver(),
    //   );
    // }, override: true);

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
      if (!_isLoaded) return;
      final tile = _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.tryLoadSprite(overlay: true);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainAnimation', (
        {positionalArgs, namedArgs}) {
      if (!_isLoaded) return;
      final tile = _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearAnimation();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlaySprite', (
        {positionalArgs, namedArgs}) {
      if (!_isLoaded) return;
      final tile = _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearOverlaySprite();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('clearTerrainOverlayAnimation',
        ({positionalArgs, namedArgs}) {
      if (!_isLoaded) return;
      final tile = _scene.map.getTerrain(positionalArgs[0], positionalArgs[1]);
      tile?.clearOverlayAnimation();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'freezePlayer', ({positionalArgs, namedArgs}) => playerFreezed = true,
        override: true);

    engine.hetu.interpreter.bindExternalFunction('unfreezePlayer',
        ({positionalArgs, namedArgs}) => playerFreezed = false,
        override: true);

    engine.hetu.interpreter.bindExternalFunction('moveObjectTo', (
        {positionalArgs, namedArgs}) {
      assert(_scene.map.movingObjects.containsKey(positionalArgs[0]));
      final completer = Completer();
      final int toX = positionalArgs[1];
      final int toY = positionalArgs[2];
      final String? endDirString = namedArgs['endDirection'];
      TileMapDirectionOrthogonal? endDirection;
      if (endDirString != null) {
        endDirection = TileMapDirectionOrthogonal.values
            .singleWhere((element) => element.name == endDirString);
      }
      final HTFunction? destionationCallback =
          namedArgs['onDestionationCallback'];
      final object = _scene.map.movingObjects[positionalArgs[0]]!;
      final route = _calculateRoute(
          fromX: object.left, fromY: object.top, toX: toX, toY: toY);
      if (route != null) {
        _scene.map.moveObjectToTilePositionByRoute(
          object,
          List<int>.from(route),
          endDirection: endDirection,
          onDestinationCallback: () {
            destionationCallback?.call();
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
        'refreshNpcsInHeroWorldMapPosition',
        ({positionalArgs, namedArgs}) => _refreshNpcsInHeroWorldMapPosition(),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshNpcsInHeroLocation',
        ({positionalArgs, namedArgs}) => _refreshNpcsInHeroLocation(),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshNpcsInHeroSite',
        ({positionalArgs, namedArgs}) => _refreshNpcsInHeroSite(),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('enterLocation',
        ({positionalArgs, namedArgs}) => _enterLocation(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('updateWorldHistory', (
        {positionalArgs, namedArgs}) {
      if (mounted) {
        context.read<HistoryState>().update();
      }
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('updateDungeonHistory', (
        {positionalArgs, namedArgs}) {
      // TODO: dungeon history
    }, override: true);

    engine.addEventListener(
      GameEvents.mapLoaded,
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, args, scene) {
          _onMapLoaded();
        },
      ),
    );

    // engine.bgm.initialize();
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);
    // FlameAudio.bgm.stop();
    // FlameAudio.bgm.dispose();

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

    scene.map.onTap = _onMapTapped;

    _isLoaded = true;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // pass the build context to script
    // final screenSize = MediaQuery.sizeOf(context);

    // ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return FutureBuilder(
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
          final screenWidgets = [
            SceneWidget(scene: _scene),
            if (context.watch<SelectedTileState>().hero != null)
              const Positioned(
                left: 0,
                top: 0,
                child: HeroInfoPanel(
                    // heroData: _heroData!,
                    // currentTerrainObject: _currentTerrain,
                    // currentLocationData: _situatedLocation,
                    ),
              ),
            if (_questData != null)
              Positioned(
                left: 330,
                top: 0,
                child: QuestInfoPanel(characterData: _heroData!),
              ),
            (context.watch<GameDialogState>().isStarted || _playerFreezed)
                ? Container()
                : const Positioned(
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
                      _scene.map.saveMovingObjectsFrameData();
                      String worldId = engine.hetu.invoke('getWorldId');
                      String? saveName = engine.hetu.invoke('getSaveName');
                      context
                          .read<Saves>()
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

                    case WorldMapDropMenuItems.saveAs:
                      _scene.map.saveMovingObjectsFrameData();
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
                        String worldId = engine.hetu.invoke('getWorldId');
                        context
                            .read<Saves>()
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
                    case WorldMapDropMenuItems.info:
                      showDialog(
                          context: context,
                          builder: (context) => const WorldInformationPanel());
                    case WorldMapDropMenuItems.viewNone:
                      _scene.map.colorMode = kColorModeNone;
                    case WorldMapDropMenuItems.viewZones:
                      _scene.map.colorMode = kColorModeZone;
                    case WorldMapDropMenuItems.viewOrganizations:
                      _scene.map.colorMode = kColorModeOrganization;
                    case WorldMapDropMenuItems.console:
                      showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            Console(engine: engine),
                      ).then((_) => setState(() {}));
                    case WorldMapDropMenuItems.exit:
                      context.read<SelectedTileState>().clearTerrain();
                      _scene.leave(clearCache: true);
                      _isDisposing = true;
                      engine.hetu.invoke('resetGame');
                      Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ];

          final selectedTerrain = _scene.map.selectedTerrain;
          if (_menuPosition != null) {
            if (selectedTerrain != null) {
              // final terrainData = selectedTerrain.data;
              final characters = _scene.map.selectedActors;
              final tileObjectHero = _scene.map.hero;
              List<int>? route;
              var isTappingHeroPosition = false;
              if (tileObjectHero != null) {
                isTappingHeroPosition =
                    selectedTerrain.tilePosition == tileObjectHero.tilePosition;
                if (!isTappingHeroPosition) {
                  final start = engine.hetu.invoke('getTerrainByWorldPosition',
                      positionalArgs: [
                        tileObjectHero.left,
                        tileObjectHero.top
                      ]);
                  final end = engine.hetu
                      .invoke('getTerrainByWorldPosition', positionalArgs: [
                    selectedTerrain.left,
                    selectedTerrain.top,
                  ]);
                  List? calculatedRoute = engine.hetu.invoke('calculateRoute',
                      positionalArgs: [start, end, _scene.worldData]);
                  if (calculatedRoute != null) {
                    route = List<int>.from(calculatedRoute);
                  }
                }
              }

              screenWidgets.add(
                WorldMapPopup(
                  left: _menuPosition!.x - WorldMapPopup.defaultSize / 2,
                  top: _menuPosition!.y - WorldMapPopup.defaultSize / 2,
                  onPanelTapped: closePopup,
                  moveToIcon: route != null,
                  onMoveTo: () {
                    _scene.map.moveObjectToTilePositionByRoute(
                        _scene.map.hero!, route!,
                        onDestinationCallback: () {});
                    closePopup();
                  },
                  enterIcon:
                      ((route != null && selectedTerrain.locationId != null) ||
                              (isTappingHeroPosition &&
                                  selectedTerrain.locationId != null))
                          ? true
                          : false,
                  onEnter: () {
                    if (route != null) {
                      _scene.map.moveObjectToTilePositionByRoute(
                        _scene.map.hero!,
                        route,
                        onDestinationCallback: () =>
                            _enterLocation(selectedTerrain.locationId!),
                      );
                    } else if (isTappingHeroPosition) {
                      _enterLocation(selectedTerrain.locationId!);
                    }
                    closePopup();
                  },
                  talkIcon: characters != null ? true : false,
                  onTalk: closePopup,
                  restIcon: isTappingHeroPosition,
                  onRest: closePopup,
                  // practiceIcon: isTappingHeroPosition &&
                  //     terrainData?['locationId'] == null,
                  // onPractice: () {},
                  interactIcon: selectedTerrain.locationId == null,
                  onInteract: () {
                    if (route != null) {
                      _scene.map.moveObjectToTilePositionByRoute(
                          _scene.map.hero!, route, onDestinationCallback: () {
                        _interactTerrain(selectedTerrain);
                      });
                    } else if (isTappingHeroPosition) {
                      _interactTerrain(selectedTerrain);
                    }
                    closePopup();
                  },
                  // description: stringBuffer.toString(),
                ),
              );
            }
          }

          return Material(
            color: Colors.transparent,
            child: Stack(
              children: screenWidgets,
            ),
          );
        }
      },
    );
  }
}
