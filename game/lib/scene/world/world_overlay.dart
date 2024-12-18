import 'dart:async';
import 'dart:math' as math;

// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
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
import 'package:provider/provider.dart';
import 'package:samsara/components/fading_text.dart';

import '../../data.dart';
import '../../../scene/loading_screen.dart';
import '../../../dialog/game_dialog/game_dialog.dart';
import '../quest_info.dart';
// import '../../../event/ui.dart';
import '../../view/world_infomation/world_infomation.dart';
import 'popup.dart';
// import '../../../shared/constants.dart';
import '../history_info.dart';
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
import '../common.dart';
import '../../events.dart';
import '../../common.dart';
import 'npc_list.dart';
import '../../dialog/input_string.dart';
// import '../../extensions.dart';
// import '../../state/quest.dart';
import '../../logic/interaction.dart';

const kExcludeTerrainKindsOnLighting = ['empty', 'mountain'];

class WorldOverlay extends StatefulWidget {
  WorldOverlay({
    required this.args,
    this.isNewGame = true,
  }) : super(key: UniqueKey());

  final bool isNewGame;
  final Map<String, dynamic> args;

  @override
  State<WorldOverlay> createState() => _WorldOverlayState();
}

class _WorldOverlayState extends State<WorldOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  WorldMapScene? _scene;

  WorldMapScene get scene {
    assert(_scene != null);
    return _scene!;
  }

  bool _isLoading = false;
  bool _isLoaded = false;

  dynamic _heroData;

  Vector2? _menuPosition;

  TileMapTerrain? _currentTerrain;
  dynamic _currentZone;
  dynamic _currentNation;
  dynamic _currentLocation;
  Iterable<dynamic> _npcsInHeroPosition = [];

  bool _playerFreezed = false;
  set playerFreezed(bool value) {
    _playerFreezed = scene.map.autoUpdateMovingObject = value;

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
      context.read<SelectedTileState>().update(
            currentZoneData: _currentZone,
            currentNationData: _currentNation,
            currentLocationData: _currentLocation,
            currentTerrainObject: _currentTerrain,
          );
    }
  }

  Future<void> _refreshNpcsInHeroWorldMapPosition() async {
    _npcsInHeroPosition =
        engine.hetu.invoke('getNpcsByWorldMapPosition', positionalArgs: [
      _heroData?['worldPosition']['left'],
      _heroData?['worldPosition']['top'],
    ]);

    if (mounted) {
      context.read<CurrentNpcList>().updated(_npcsInHeroPosition);
    }
  }

  Future<void> _refreshNpcsInHeroLocation() async {
    final npcsInHeroLocation =
        engine.hetu.invoke('getNpcsByLocationId', positionalArgs: [
      _heroData?['locationId'],
    ]);

    if (mounted) {
      context.read<CurrentNpcList>().updated(npcsInHeroLocation);
    }
  }

  Future<void> _refreshNpcsInHeroSite() async {
    final npcsInHeroSite =
        engine.hetu.invoke('getNpcsByLocationAndSiteId', positionalArgs: [
      _heroData?['locationId'],
      _heroData?['siteId'],
    ]);

    if (mounted) {
      context.read<CurrentNpcList>().updated(npcsInHeroSite);
    }
  }

  Future<void> _refreshMap() async {
    Iterable<dynamic> npcsOnWorldMap =
        engine.hetu.invoke('getNpcsOnWorldMap', positionalArgs: [scene.map.id]);

    final charIds = npcsOnWorldMap.map((value) => value['id']);

    final toBeRemoved = [];
    for (final obj in scene.map.movingObjects.values) {
      if (!charIds.contains(obj.id)) {
        toBeRemoved.add(obj.id);
      }
    }

    for (final id in toBeRemoved) {
      scene.map.removeMovingObject(id);
    }

    for (final char in npcsOnWorldMap) {
      final charId = char['id'];
      if (!scene.map.movingObjects.containsKey(charId)) {
        scene.map.loadMovingObjectFromData(char, (left, top) {
          engine.hetu.invoke('setCharacterWorldPosition',
              positionalArgs: [char, left, top]);
        });
      } else {
        assert(char['worldPosition'] != null);
        final object = scene.map.movingObjects[charId]!;
        object.tilePosition = TilePosition(
            char['worldPosition']['left'], char['worldPosition']['top']);
        scene.map.refreshTileInfo(object);
      }
    }

    _refreshNpcsInHeroWorldMapPosition();

    if (mounted) {
      context.read<HistoryState>().update();
    }
  }

  Future<void> _onHeroMoved(int left, int top) async {
    final blocked = movableTest(left, top);
    if (blocked != null) {
      // 如果blocked有值，无论真假，都会停止移动
      if (blocked) {
        // 让英雄返回上一格
        scene.map.cancelObjectMoving(scene.map.hero!);
        return;
      } else {
        // 让英雄停在这一格
        scene.map.hero!.isMovingCanceled = true;
      }
    }

    final lightedAreaSize = _heroData!['stats']['lightRadius'];
    scene.map.lightUpAroundTile(
      scene.map.hero!.tilePosition,
      size: lightedAreaSize,
      excludeTerrainKinds: kExcludeTerrainKindsOnLighting,
    );

    engine.hetu.invoke('setHeroWorldPosition', positionalArgs: [left, top]);

    currentTerrain = scene.map.getTerrainAtHero();

    if (scene.isMainWorld) {
      engine.hetu.invoke('updateGame');
    }

    await _refreshMap();

    // 如果英雄所在格子只有一个npc，则默认直接和该npc互动
    // if (_npcsInHeroPosition.length == 1) {
    //   final npcId = _npcsInHeroPosition.first['id'];
    //   engine.hetu.invoke('onInteractCharacter', positionalArgs: [npcId]);
    // }
  }

  Future<void> _interactTerrain(TileMapTerrain terrain) async {
    await engine.hetu
        .invoke('onInteractTerrain', positionalArgs: [terrain.data]);
  }

  Future<void> _tryEnterLocation(String locationId) async {
    final locationData =
        engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);

    if (!(locationData['isDiscovered'] ?? false)) {
      engine.warn('location ${locationData['id']} is not discovered yet.');
      return;
    }

    await engine.hetu
        .invoke('onBeforeHeroEnterLocation', positionalArgs: [locationData]);

    // if (!context.mounted) return;
    if (locationData['isDiscovered'] == true) {
      if (mounted) {
        scene.bgm.pause();
        final Iterable<dynamic> npcs = engine.hetu.invoke('getNpcsByLocationId',
            positionalArgs: [locationData['id']]);
        context.read<CurrentNpcList>().updated(npcs);

        await showDialog(
          context: context,
          builder: (context) => LocationSiteSceneOverlay(
            key: UniqueKey(),
            terrainObject: _currentTerrain,
            locationData: locationData,
          ),
        );

        scene.bgm.resume();

        _refreshNpcsInHeroWorldMapPosition();
      }
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
        positionalArgs: [fromX, fromY, scene.worldData]);
    toTile ??= engine.hetu.invoke('getTerrainByWorldPosition',
        positionalArgs: [toX, toY, scene.worldData]);
    List? calculatedRoute = engine.hetu.invoke(
      'calculateRoute',
      positionalArgs: [fromTile, toTile, scene.worldData],
      namedArgs: {'terrainKinds': terrainKinds},
    );
    return calculatedRoute;
  }

  void _onMapTapped(int buttons, Vector2 position) {
    if (_playerFreezed) return;

    final tilePosition = scene.map.worldPosition2Tile(position);
    // addHintText('test', tilePosition.left, tilePosition.top);

    final hero = scene.map.hero;
    if (hero == null) return;
    if (_menuPosition != null) {
      setState(() {
        _menuPosition = null;
      });
    } else {
      if (buttons == kPrimaryButton) {
        if (tilePosition == scene.map.selectedTerrain?.tilePosition) {
          if (!scene.map.isTileVisible(tilePosition.left, tilePosition.top)) {
            return;
          }
          if (hero.isMoving) return;
          final terrain = scene.map.selectedTerrain;
          if (terrain!.terrainKind == TileMapTerrainKind.empty) return;
          if (terrain.tilePosition != hero.tilePosition) {
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
              scene.map.moveObjectToTilePositionByRoute(scene.map.hero!, route,
                  onDestinationCallback: (tile) {
                engine.hetu
                    .invoke('onAfterHeroMove', positionalArgs: [tile.data]);
              });
            }
          } else {
            engine.hetu.invoke('senseTerrain', positionalArgs: [terrain.data]);
          }
        } else {
          if (scene.map.trySelectTile(tilePosition.left, tilePosition.top)) {
            currentTerrain = scene.map.selectedTerrain;
          }
        }
      } else if (buttons == kSecondaryButton) {
        if (tilePosition == scene.map.selectedTerrain?.tilePosition &&
            _currentTerrain != null) {
          if (!scene.map
              .isTileVisible(_currentTerrain!.left, _currentTerrain!.top)) {
            return;
          }
          setState(() {
            _menuPosition = scene.map.tilePosition2TileCenterInScreen(
                _currentTerrain!.left, _currentTerrain!.top);
          });
        }
      }
    }
  }

  Future<void> _onMapLoaded() async {
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

      engine.hetu
          .invoke('init', namedArgs: {'itemsData': GameData.itemsData.values});

      for (final id in GameConfig.modules.keys) {
        if (GameConfig.modules[id]?['enabled'] == true) {
          final moduleConfig = {'version': kGameVersion};
          engine.hetu
              .invoke('init', module: id, positionalArgs: [moduleConfig]);
        }
      }

      engine.hetu.invoke('onNewGame');
    }

    assert(_heroData != null);
    await scene.map.loadHeroFromData(_heroData, _onHeroMoved);
    if (mounted) {
      context.read<HeroState>().update();
    }

    engine.hetu.invoke('refreshWorldMapCaptions');

    final lightedAreaSize = _heroData!['stats']['lightRadius'];
    scene.map.lightUpAroundTile(
      scene.map.hero!.tilePosition,
      size: lightedAreaSize,
      excludeTerrainKinds: kExcludeTerrainKindsOnLighting,
    );
    scene.map.moveCameraToTilePosition(
        scene.map.hero!.left, scene.map.hero!.top,
        animated: false);

    currentTerrain = scene.map.getTerrainAtHero();

    await _refreshMap();

    if (mounted) {
      context.read<HistoryState>().update();
    }

    _isLoading = false;
    setState(() {});
  }

  void closePopup() {
    setState(() {
      _menuPosition = null;
    });
  }

  void addHintText(text, left, top, {double duration = 1.5, Color? color}) {
    final position = scene.map.tilePosition2TileCenterInWorld(left, top) *
        scene.map.scaleFactor;

    final c2 = FadingText(
      text,
      position:
          Vector2(position.x + math.Random().nextDouble() * 10 - 5, position.y),
      movingUpOffset: 20,
      duration: duration,
      config: ScreenTextConfig(
        textStyle: TextStyle(
          color: color ?? Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'RuiZiYunZiKuLiBianTiGBK',
        ),
      ),
      priority: kHintTextPriority,
    );
    scene.world.add(c2);
  }

  @override
  void initState() {
    super.initState();

    // engine.hetu.interpreter.bindExternalFunction('showWorldMapGameOver', (
    //     {positionalArgs, namedArgs}) {
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) => const GameOver(),
    //   );
    // }, override: true);

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

    engine.hetu.interpreter.bindExternalFunction(
        'freezePlayer', ({positionalArgs, namedArgs}) => playerFreezed = true,
        override: true);

    engine.hetu.interpreter.bindExternalFunction('unfreezePlayer',
        ({positionalArgs, namedArgs}) => playerFreezed = false,
        override: true);

    engine.hetu.interpreter.bindExternalFunction('refreshHeroTileInfo', (
        {positionalArgs, namedArgs}) {
      scene.map.hero!.tilePosition = TilePosition(
          _heroData['worldPosition']['left'],
          _heroData['worldPosition']['top']);
      scene.map.refreshTileInfo(scene.map.hero!);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('setObjectTo', (
        {positionalArgs, namedArgs}) {
      assert(scene.map.movingObjects.containsKey(positionalArgs[0]));
      final object = scene.map.movingObjects[positionalArgs[0]]!;
      object.tilePosition = TilePosition(positionalArgs[1], positionalArgs[2]);
      scene.map.refreshTileInfo(object);
      engine.hetu.invoke('setEntityWorldPosition',
          positionalArgs: [object.data, positionalArgs[1], positionalArgs[2]]);
    });

    engine.hetu.interpreter.bindExternalFunction('moveObjectTo', (
        {positionalArgs, namedArgs}) {
      assert(scene.map.movingObjects.containsKey(positionalArgs[0]));
      final completer = Completer();
      final int toX = positionalArgs[1];
      final int toY = positionalArgs[2];
      final String? endDirString = namedArgs['endDirection'];
      OrthogonalDirection? endDirection;
      if (endDirString != null) {
        endDirection = OrthogonalDirection.values
            .singleWhere((element) => element.name == endDirString);
      }
      final HTFunction? destionationCallback =
          namedArgs['onDestionationCallback'];
      final object = scene.map.movingObjects[positionalArgs[0]]!;
      final route = _calculateRoute(
          fromX: object.left, fromY: object.top, toX: toX, toY: toY);
      if (route != null) {
        scene.map.moveObjectToTilePositionByRoute(
          object,
          List<int>.from(route),
          endDirection: endDirection,
          onDestinationCallback: (tile) {
            destionationCallback?.call(positionalArgs: [tile.data]);
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

    engine.hetu.interpreter.bindExternalFunction('addHintText', (
        {positionalArgs, namedArgs}) {
      final hexString = positionalArgs[3];
      Color? color;
      if (hexString != null) {
        color = HexColor.fromString(hexString);
      }
      addHintText(
        positionalArgs[0],
        positionalArgs[1],
        positionalArgs[2],
        color: color,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'moveCameraToMapPosition',
        ({positionalArgs, namedArgs}) => scene.map
            .moveCameraToTilePosition(positionalArgs[0], positionalArgs[1]),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('lightUpAroundTile', (
        {positionalArgs, namedArgs}) {
      scene.map.lightUpAroundTile(
        TilePosition(positionalArgs[0], positionalArgs[1]),
        size: positionalArgs[2],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'enterLocation',
        ({positionalArgs, namedArgs}) =>
            _tryEnterLocation(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('setFog', (
        {positionalArgs, namedArgs}) {
      scene.map.showFogOfWar = positionalArgs.first;
    }, override: true);

    engine.addEventListener(
      GameEvents.mapLoaded,
      EventHandler(
        widgetKey: widget.key!,
        handle: (id, args, scene) {
          _onMapLoaded();
        },
      ),
    );
  }

  Future<bool> _prepareData() async {
    if (_isLoaded) return true;
    if (_isLoading) return false;
    _isLoading = true;

    if (!GameData.isGameCreated) {
      if (widget.args['method'] == 'preset') {
        await GameData.loadPreset(widget.args['path']);
      } else if (widget.args['method'] == 'load') {
        await GameData.loadGame(widget.args['path']);
      } else {
        await GameData.newGame(widget.args['id'], widget.args['saveName']);
      }
    }
    if (mounted) {
      final isReload =
          await context.read<WorldMapSceneState>().pushScene(args: widget.args);
      if (isReload) {
        _isLoading = false;
      }
    }
    _isLoaded = true;
    return true;
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
          _scene = context.watch<WorldMapSceneState>().scene;

          if (_scene == null) {
            return const LoadingScreen();
          }

          scene.map.onTap = _onMapTapped;

          final screenWidgets = [
            SceneWidget(scene: scene),
            if (_isLoading || scene.isLoading) const LoadingScreen(),
            const Positioned(
              left: 0,
              top: 0,
              child: HeroInfoPanel(),
            ),
            const Positioned(
              right: 0,
              top: 100,
              child: QuestInfoPanel(),
            ),
            if (_heroData != null &&
                (!context.watch<GameDialogState>().isStarted &&
                    !_playerFreezed))
              const Positioned(
                left: 20,
                top: 150,
                child: NpcList(),
              ),
            const Positioned(
              left: 0.0,
              bottom: 0.0,
              child: HistoryInfoPanel(),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: WorldMapDropMenu(
                onSelected: (WorldMapDropMenuItems item) async {
                  switch (item) {
                    case WorldMapDropMenuItems.save:
                      scene.map.saveMovingObjectsFrameData();
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
                      scene.map.saveMovingObjectsFrameData();
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
                      scene.map.colorMode = kColorModeNone;
                    case WorldMapDropMenuItems.viewZones:
                      scene.map.colorMode = kColorModeZone;
                    case WorldMapDropMenuItems.viewOrganizations:
                      scene.map.colorMode = kColorModeOrganization;
                    case WorldMapDropMenuItems.console:
                      showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            Console(engine: engine),
                      ).then((_) => setState(() {}));
                    case WorldMapDropMenuItems.exit:
                      context.read<SelectedTileState>().clear();
                      scene.leave(clearCache: true);
                      Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ];

          if (_menuPosition != null) {
            if (_currentTerrain != null) {
              // final terrainData = selectedTerrain.data;
              // final characters = scene.map.selectedActors;
              final tileObjectHero = scene.map.hero;
              List<int>? route;
              bool isTappingHeroPosition = false;
              if (tileObjectHero != null) {
                isTappingHeroPosition = _currentTerrain!.tilePosition ==
                    tileObjectHero.tilePosition;
                if (!isTappingHeroPosition) {
                  final movableTerrainKinds = engine.hetu.invoke(
                      'getCharacterMovableTerrainKinds',
                      positionalArgs: [_heroData]);
                  final start = engine.hetu.invoke('getTerrainByWorldPosition',
                      positionalArgs: [
                        tileObjectHero.left,
                        tileObjectHero.top
                      ]);
                  final end = engine.hetu
                      .invoke('getTerrainByWorldPosition', positionalArgs: [
                    _currentTerrain!.left,
                    _currentTerrain!.top,
                  ]);
                  List? calculatedRoute = engine.hetu.invoke(
                    'calculateRoute',
                    positionalArgs: [start, end, scene.worldData],
                    namedArgs: {'terrainKinds': movableTerrainKinds},
                  );
                  if (calculatedRoute != null) {
                    route = List<int>.from(calculatedRoute);
                  }
                }
              }

              bool isLocationDiscovered = false;

              if ((route != null && _currentTerrain!.locationId != null) ||
                  (isTappingHeroPosition &&
                      _currentTerrain!.locationId != null)) {
                final location = engine.hetu.invoke('getLocationById',
                    positionalArgs: [_currentTerrain!.locationId]);
                isLocationDiscovered = location['isDiscovered'];
              }

              final genre = engine.hetu.invoke('getHeroMainGenre');

              screenWidgets.add(
                WorldMapPopup(
                  left: _menuPosition!.x - WorldMapPopup.defaultSize / 2,
                  top: _menuPosition!.y - WorldMapPopup.defaultSize / 2,
                  onPanelTapped: closePopup,
                  moveToIcon: !isTappingHeroPosition && route != null,
                  onMoveTo: () {
                    closePopup();
                    scene.map.moveObjectToTilePositionByRoute(
                      scene.map.hero!,
                      route!,
                      onDestinationCallback: (tile) {
                        engine.hetu.invoke('onAfterHeroMove',
                            positionalArgs: [tile.data]);
                      },
                    );
                  },
                  enterIcon: isLocationDiscovered,
                  onEnter: () {
                    closePopup();
                    if (route != null) {
                      scene.map.moveObjectToTilePositionByRoute(
                          scene.map.hero!, route,
                          onDestinationCallback: (tile) {
                        engine.hetu.invoke('onAfterHeroMove',
                            positionalArgs: [tile.data]);
                      });
                    } else if (isTappingHeroPosition) {
                      engine.hetu.invoke('onAfterHeroMove',
                          positionalArgs: [_currentTerrain!.data]);
                    }
                  },
                  exploreIcon: (isTappingHeroPosition &&
                      _currentTerrain!.locationId == null),
                  onExplore: () {
                    closePopup();
                    engine.hetu.invoke('onHeroExplore',
                        positionalArgs: [_currentTerrain!.data]);
                  },
                  meditateIcon: isTappingHeroPosition,
                  onMeditate: () {
                    closePopup();
                    engine.hetu.invoke(
                      'onHeroMeditate',
                      namedArgs: {'terrain': _currentTerrain!.data},
                    );
                  },
                  interactIcon: isTappingHeroPosition &&
                      _currentTerrain!.locationId == null,
                  onInteract: () {
                    closePopup();
                    if (route != null) {
                      scene.map.moveObjectToTilePositionByRoute(
                          scene.map.hero!, route,
                          onDestinationCallback: (tile) {
                        _interactTerrain(tile);
                      });
                    } else if (isTappingHeroPosition) {
                      _interactTerrain(_currentTerrain!);
                    }
                  },
                  skillIcon: !isTappingHeroPosition && (genre != null),
                  onSkill: () {
                    closePopup();
                    switch (genre) {
                      case 'blade':
                        final start = scene.map.hero!.centerPosition;
                        final end = _currentTerrain!.centerPosition;
                        scene.useMapSkillBlade(start, end);
                      case 'element':
                      case 'physique':
                      case 'vitality':
                      case 'avatar':
                    }
                  },
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
