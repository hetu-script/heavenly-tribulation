import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/pages/map/quest_info.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:samsara/event/tilemap.dart';
import 'package:samsara/tilemap.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/ui/flutter/loading_screen.dart';
import 'package:samsara/console.dart';

import '../../../event/ui.dart';
import '../../../ui/view/information/information.dart';
import 'popup.dart';
import '../../../shared/json.dart';
import '../../../shared/constants.dart';
import '../history_panel.dart';
import '../../../config.dart';
import '../../../scene/worldmap.dart';
import '../hero_info.dart';
import 'drop_menu.dart';
import '../../../ui/view/location/location.dart';
import '../../../ui/dialog/character_select_dialog.dart';
import '../../../ui/dialog/game_over.dart';
import '../common.dart';

const kColorModeZone = 0;
const kColorModeOrganization = 1;

const kTerrainKindLocation = 'location';
const kTerrainKindLake = 'lake';
const kTerrainKindSea = 'sea';
const kTerrainKindMountain = 'mountain';
const kTerrainKindForest = 'forest';
const kTerrainKindPlain = 'plain';
const kTerrainKindRiver = 'river';
const kTerrainKindRoad = 'road';

const kMinHeroAge = 10;
const kMaxHeroAge = 20;

class WorldOverlay extends StatefulWidget {
  const WorldOverlay({
    required super.key,
    required this.args,
  });

  final Map<String, dynamic> args;

  @override
  State<WorldOverlay> createState() => _WorldOverlayState();
}

class _WorldOverlayState extends State<WorldOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late WorldMapScene _scene;

  HTStruct? _heroData, _questData;

  Vector2? _menuPosition;

  bool _isDisposing = false;

  TileMapTerrain? _currentTerrain;
  set currentTerrain(TileMapTerrain? terrain) {
    _currentTerrain = terrain;
    if (_currentTerrain != null) {
      final String? locationId = _currentTerrain!.locationId;

      // final nationId = _currentTerrain!.nationId;
      // if (nationId != null) {
      //   _situatedNation =
      //       engine.hetu.invoke('getOrganizationById', positionalArgs: [nationId]);
      // } else {
      //   _situatedNation = null;
      // }

      if (locationId != null) {
        _situatedLocation =
            engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);
      } else {
        _situatedLocation = null;
      }
    }
    setState(() {});
  }

  HTStruct? _situatedLocation;
  // HTStruct? _situatedNation;

  void _interactTerrain(TileMapTerrain terrain) async {
    await engine.hetu.invoke('handleWorldTerrainInteraction',
        positionalArgs: [terrain.left, terrain.top]);
  }

  void _tryEnterLocation(String locationId) async {
    final locationData =
        engine.hetu.invoke('getLocationById', positionalArgs: [locationId]);
    if (!context.mounted) return;
    if (locationData['flags']['isDiscovered'] == true) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => LocationView(locationData: locationData),
      );
    }
    await engine.hetu
        .invoke('onHeroEnteredLocation', positionalArgs: [locationData]);
  }

  void _mapTapHandler(GameEvent event) {
    final e = event as MapInteractionEvent;
    if (engine.config.isOnDesktop) {
      if (e.buttons & kPrimaryButton == kPrimaryButton) {
        if (_menuPosition != null) {
          _menuPosition = null;
        } else {
          _scene.map.selectTile(e.tilePosition.left, e.tilePosition.top);
          final hero = _scene.map.hero;
          if (hero == null) return;
          if (hero.isMoving) return;
          final terrain = _scene.map.selectedTerrain;
          if (terrain == null) return;
          List<int>? route;
          if (terrain.tilePosition != hero.tilePosition) {
            final start = engine.hetu.invoke('getTerrain',
                positionalArgs: [hero.left, hero.top, _scene.worldData]);
            final end = engine.hetu.invoke('getTerrain',
                positionalArgs: [terrain.left, terrain.top, _scene.worldData]);
            List? calculatedRoute = engine.hetu.invoke('calculateRoute',
                positionalArgs: [start, end, _scene.worldData]);
            if (calculatedRoute != null) {
              route = List<int>.from(calculatedRoute);
              if (terrain.locationId != null) {
                _scene.map.moveHeroToTilePositionByRoute(
                  route,
                  onDestinationCallback: () =>
                      _tryEnterLocation(terrain.locationId!),
                );
              } else {
                _scene.map.moveHeroToTilePositionByRoute(route);
              }
            }
          } else {
            if (terrain.locationId != null) {
              _tryEnterLocation(terrain.locationId!);
            }
          }
        }
      } else if (e.buttons & kSecondaryButton == kSecondaryButton) {
        if (_scene.map.hero?.isMoving ?? false) return;
        _scene.map.selectTile(e.tilePosition.left, e.tilePosition.top);
        setState(() {
          _menuPosition = _scene.map.tilePosition2TileCenterInScreen(
              e.tilePosition.left, e.tilePosition.top);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    engine.hetu.invoke('build', positionalArgs: [context]);

    engine.hetu.interpreter.bindExternalFunction(
        'showWorldMapGameOver',
        ({positionalArgs, namedArgs}) => showDialog(
              context: context,
              builder: (BuildContext context) => const GameOver(),
            ),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('setWorldMapCaption', (
        {positionalArgs, namedArgs}) {
      _scene.map.setTerrainCaption(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('setWorldMapSprite', (
        {positionalArgs, namedArgs}) {
      _scene.map.setTerrainSprite(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('setWorldMapOverlaySprite', (
        {positionalArgs, namedArgs}) {
      _scene.map.setTerrainOverlaySprite(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('enterLocation', (
        {positionalArgs, namedArgs}) {
      _tryEnterLocation(positionalArgs.first);
    }, override: true);

    engine.addEventListener(
      MapEvents.mapTapped,
      EventHandler(ownerKey: widget.key!, handle: _mapTapHandler),
    );

    // engine.addEventListener(
    //   Events.mapDoubleTapped,
    //   EventHandler(widget.key!, _mapTapHandler),
    // );

    // engine.addEventListener(
    //   Events.mapTapped,
    //   EventHandler(widget.key!, (event) {
    //     final e = event as MapInteractionEvent;
    //     if (_menuPosition != null) {
    //       setState(() {
    //         _menuPosition = null;
    //       });
    //     } else if (e.buttons & kSecondaryButton == kSecondaryButton) {
    //       if (_scene.map.hero?.isMoving ?? false) return;
    //       setState(() {
    //         _menuPosition = _scene.map.tilePosition2TileCenterInScreen(
    //             e.tilePosition.left, e.tilePosition.top);
    //       });
    //     }
    //   }),
    // );

    engine.addEventListener(
      MapEvents.loadedMap,
      EventHandler(
        ownerKey: widget.key!,
        handle: (GameEvent event) async {
          if ((event as MapLoadedEvent).isFirstLoad) {
            final charactersData = engine.hetu.invoke('getCharacters');
            final Iterable filteredCharacters =
                (charactersData.values as Iterable).where((character) {
              final age = engine.hetu
                  .invoke('getCharacterAge', positionalArgs: [character]);
              if (age >= kMinHeroAge && age < kMaxHeroAge) {
                return true;
              }
              return false;
            });
            final key = await CharacterSelectDialog.show(
              context: context,
              title: engine.locale['selectHero'],
              charactersData: filteredCharacters,
              showCloseButton: false,
            );
            engine.hetu.invoke('setHeroId', positionalArgs: [key]);
            final heroHome = engine.hetu.invoke('getHeroHomeLocation');
            engine.hetu.invoke('discoverLocation', positionalArgs: [heroHome]);
            engine.hetu.invoke('onGameEvent', positionalArgs: ['onNewGame']);
          }
          _heroData = engine.hetu.invoke('getHero');
          final charSheet = SpriteSheet(
            image:
                await Flame.images.load('animation/tile_character_default.png'),
            srcSize: kTileMapHeroSpriteSrcSize,
          );
          final shipSheet = SpriteSheet(
            image: await Flame.images.load('animation/tile_ship_default.png'),
            srcSize: kTileMapHeroSpriteSrcSize,
          );
          _scene.map.hero = TileMapObject(
            engine: engine,
            sceneId: _scene.id,
            isHero: true,
            moveAnimationSpriteSheet: charSheet,
            swimAnimationSpriteSheet: shipSheet,
            left: _heroData!['worldPosition']['left'],
            top: _heroData!['worldPosition']['top'],
            tileShape: _scene.map.tileShape,
            tileMapWidth: _scene.map.tileMapWidth,
            gridWidth: _scene.map.gridWidth,
            gridHeight: _scene.map.gridHeight,
            srcWidth: kTileMapHeroSpriteSrcSize.x,
            srcHeight: kTileMapHeroSpriteSrcSize.y,
          );
          currentTerrain = _scene.map.getTerrain(
              _heroData!['worldPosition']['left'],
              _heroData!['worldPosition']['top']);

          setState(() {});
        },
      ),
    );

    engine.addEventListener(
      MapEvents.heroMoved,
      EventHandler(
        ownerKey: widget.key!,
        handle: (GameEvent event) {
          final heroEvent = event as HeroEvent;
          if (heroEvent.scene == 'worldmap') {
            engine.hetu.invoke('setHeroPosition', positionalArgs: [
              heroEvent.tilePosition.left,
              heroEvent.tilePosition.top,
            ]);

            engine.hetu.invoke('updateGame');
            currentTerrain = _scene.map.getTerrainAtHero();
            final blocked = engine.hetu.invoke('onHeroMovedOnWorldMap',
                positionalArgs: [
                  heroEvent.tilePosition.left,
                  heroEvent.tilePosition.top
                ]);
            if (blocked != null) {
              if (blocked) {
                _scene.map.moveHeroToLastRouteNode();
              } else {
                _scene.map.hero!.isMovingCanceled = true;
              }
            }
          }
          setState(() {});
        },
      ),
    );

    engine.addEventListener(
      UIEvents.needRebuildUI,
      EventHandler(
        ownerKey: widget.key!,
        handle: (GameEvent event) {
          updateInfoPanels();
        },
      ),
    );

    engine.playBGM(
        'music/chinese-peaceful-heartwarming-harp-asian-emotional-traditional-music-21041.mp3',
        volume: GameConfig.musicVolume);
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);
    // FlameAudio.bgm.stop();
    // FlameAudio.bgm.dispose();

    _scene.detach();
    super.dispose();
  }

  void updateInfoPanels() {
    if (_heroData != null) {
      _questData = engine.hetu
          .invoke('getCharacterActiveQuest', positionalArgs: [_heroData]);
    }
    if (mounted) setState(() {});
  }

  Future<Scene?> _getScene(Map<String, dynamic> args) async {
    if (_isDisposing) return null;
    final scene = await engine.createScene(
        contructorKey: 'worldmap',
        sceneId: args['id'],
        arg: args) as WorldMapScene;
    _heroData = engine.hetu.invoke('getHero');
    updateInfoPanels();

    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // pass the build context to script
    // final screenSize = MediaQuery.of(context).size;

    // ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return _isDisposing
        ? LoadingScreen(text: engine.locale['loading'])
        : FutureBuilder(
            // 不知道为啥，这里必须用这种写法才能进入载入界面，否则一定会卡住
            future: Future.delayed(
              const Duration(milliseconds: 100),
              () => _getScene(widget.args),
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                throw (snapshot.error!);
              }

              if (!snapshot.hasData) {
                return LoadingScreen(text: engine.locale['loading']);
              } else {
                _scene = snapshot.data as WorldMapScene;
                if (_scene.isAttached) {
                  _scene.detach();
                }
                final screenWidgets = [
                  SceneWidget(scene: _scene),
                  if (_heroData != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: HeroInfoPanel(heroData: _heroData!),
                    ),
                  if (_questData != null)
                    Positioned(
                      left: 330,
                      top: 0,
                      child: QuestInfoPanel(characterData: _heroData!),
                    ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: WorldMapDropMenu(
                      onSelected: (WorldMapDropMenuItems item) async {
                        switch (item) {
                          case WorldMapDropMenuItems.info:
                            showDialog(
                                context: context,
                                builder: (context) => const InformationPanel());
                            break;
                          case WorldMapDropMenuItems.viewNone:
                            _scene.map.colorMode = kColorModeNone;
                            break;
                          case WorldMapDropMenuItems.viewZones:
                            _scene.map.colorMode = kColorModeZone;
                            break;
                          case WorldMapDropMenuItems.viewOrganizations:
                            _scene.map.colorMode = kColorModeOrganization;
                            break;
                          case WorldMapDropMenuItems.console:
                            showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  Console(engine: engine),
                            ).then((_) => setState(() {}));
                            break;
                          case WorldMapDropMenuItems.exit:
                            _saveGame().then((_) {
                              engine.leaveScene(_scene.id, clearCache: true);
                              _isDisposing = true;
                              engine.hetu.invoke('resetGame');
                              Navigator.of(context).pop();
                            });
                            break;
                          default:
                        }
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          HistoryPanel(
                            heroId: _heroData?['id'],
                            heroPosition: _heroData?['worldPosition'],
                            currentTerrain: _currentTerrain,
                            // currentNationData: _situatedNation,
                            currentLocationData: _situatedLocation,
                          ),
                          // TerrainInfoPanel(
                          //   terrainData: selectedTerrain,
                          // ),
                          // LocationInfoPanel(
                          //   locationData: selectedLocation,
                          // ),
                        ],
                      ),
                    ),
                  ),
                ];

                final selectedTerrain = _scene.map.selectedTerrain;
                if (_menuPosition != null) {
                  if (selectedTerrain != null) {
                    // final terrainData = selectedTerrain.data;
                    final characters = _scene.map.selectedActors;
                    final hero = _scene.map.hero;
                    List<int>? route;
                    var isTappingHeroPosition = false;
                    if (hero != null) {
                      isTappingHeroPosition =
                          selectedTerrain.tilePosition == hero.tilePosition;
                      if (!isTappingHeroPosition) {
                        final start = engine.hetu.invoke('getTerrain',
                            positionalArgs: [
                              hero.left,
                              hero.top,
                              _scene.worldData
                            ]);
                        final end = engine.hetu.invoke('getTerrain',
                            positionalArgs: [
                              selectedTerrain.left,
                              selectedTerrain.top,
                              _scene.worldData
                            ]);
                        List? calculatedRoute = engine.hetu.invoke(
                            'calculateRoute',
                            positionalArgs: [start, end, _scene.worldData]);
                        if (calculatedRoute != null) {
                          route = List<int>.from(calculatedRoute);
                        }
                      }
                    }

                    void closePopup() {
                      setState(() {
                        _menuPosition = null;
                        _scene.map.selectedTerrain = null;
                      });
                    }

                    // final stringBuffer = StringBuffer();

                    // stringBuffer.writeln(
                    //     '坐标: ${selectedTerrain.left}, ${selectedTerrain.top}');

                    // final zoneData = engine.hetu.invoke('getZoneByIndex',
                    //     positionalArgs: [terrainData['zoneIndex']]);
                    // final zoneName = zoneData['name'];
                    // if (zoneName != null) {
                    //   stringBuffer.writeln(zoneName);
                    // }

                    // if (selectedTerrain.nationId != null) {
                    //   final nationData = engine.hetu.invoke('getOrganizationById',
                    //       positionalArgs: [selectedTerrain.nationId]);
                    //   stringBuffer.writeln('${nationData['name']}');
                    // }

                    // if (selectedTerrain.locationId != null) {
                    //   final locationData = engine.hetu.invoke('getLocationById',
                    //       positionalArgs: [selectedTerrain.locationId]);
                    //   stringBuffer.writeln('${locationData['name']}');
                    // }

                    screenWidgets.add(
                      WorldMapPopup(
                        left: _menuPosition!.x - WorldMapPopup.defaultSize / 2,
                        top: _menuPosition!.y - WorldMapPopup.defaultSize / 2,
                        onPanelTapped: closePopup,
                        moveToIcon: route != null,
                        onMoveTo: () {
                          _scene.map.moveHeroToTilePositionByRoute(route!);
                          closePopup();
                        },
                        enterIcon: ((route != null &&
                                    selectedTerrain.locationId != null) ||
                                (isTappingHeroPosition &&
                                    selectedTerrain.locationId != null))
                            ? true
                            : false,
                        onEnter: () {
                          if (route != null) {
                            _scene.map.moveHeroToTilePositionByRoute(
                              route,
                              onDestinationCallback: () => _tryEnterLocation(
                                  selectedTerrain.locationId!),
                            );
                          } else if (isTappingHeroPosition) {
                            _tryEnterLocation(selectedTerrain.locationId!);
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
                        interactIcon: true,
                        onInteract: () {
                          if (route != null) {
                            _scene.map.moveHeroToTilePositionByRoute(route,
                                onDestinationCallback: () {
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

  Future<void> _saveGame() async {
    String? savePath = engine.hetu.invoke('getSavePath');
    if (savePath == null) {
      final worldId = engine.hetu.invoke('getWorldId');
      final directory = await path.getApplicationDocumentsDirectory();
      savePath = path.join(directory.path, GameConfig.gameTitle, 'save',
          worldId + kGameSaveFileExtension);
      engine.hetu.invoke('setSavePath', positionalArgs: [savePath]);
    }
    engine.info('保存游戏至：[$savePath]');
    final saveFile = File(savePath);
    if (!saveFile.existsSync()) {
      saveFile.createSync(recursive: true);
    }
    final gameJsonData = engine.hetu.invoke('getGameJsonData');
    final gameStringData = jsonEncodeWithIndent(gameJsonData);
    saveFile.writeAsStringSync(gameStringData);

    final saveFile2 = File('$savePath$kUniverseSaveFilePostfix');
    if (!saveFile2.existsSync()) {
      saveFile2.createSync(recursive: true);
    }
    final universeJsonData = engine.hetu.invoke('getUniverseJsonData');
    final universeStringData = jsonEncodeWithIndent(universeJsonData);
    saveFile2.writeAsStringSync(universeStringData);
  }
}
