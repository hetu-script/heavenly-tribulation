import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:heavenly_tribulation/ui/overlay/quest_info.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:samsara/tilemap.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

import '../../event/events.dart';
import '../view/information/information.dart';
import 'worldmap/popup.dart';
import '../../shared/json.dart';
import '../../shared/constants.dart';
import 'history_panel.dart';
import '../shared/loading_screen.dart';
import '../../global.dart';
import '../../scene/worldmap.dart';
import 'hero_info.dart';
import 'worldmap/drop_menu.dart';
import '../view/console.dart';
// import '../../../event/events.dart';
import '../view/location/location.dart';
import '../dialog/character_select_dialog.dart';
// import 'worldmap/terrain_info.dart';
// import 'worldmap/location_info.dart';
import '../dialog/game_over.dart';

const kTerrainKindLocation = 'location';
const kTerrainKindLake = 'lake';
const kTerrainKindSea = 'sea';
const kTerrainKindMountain = 'mountain';
const kTerrainKindForest = 'forest';
const kTerrainKindPlain = 'plain';
const kTerrainKindRiver = 'river';
const kTerrainKindRoad = 'road';

const kMinHeroAge = 15;
const kMaxHeroAge = 40;

class MainGameOverlay extends StatefulWidget {
  const MainGameOverlay({
    required super.key,
    required this.args,
  });

  final Map<String, dynamic> args;

  @override
  State<MainGameOverlay> createState() => _MainGameOverlayState();
}

class _MainGameOverlayState extends State<MainGameOverlay>
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

      final nationId = _currentTerrain!.nationId;
      if (nationId != null) {
        _currentNation =
            engine.invoke('getNationById', positionalArgs: [nationId]);
      } else {
        _currentNation = null;
      }

      if (locationId != null) {
        _currentLocation =
            engine.invoke('getLocationById', positionalArgs: [locationId]);
      } else {
        _currentLocation = null;
      }
    }
    setState(() {});
  }

  HTStruct? _currentLocation;
  HTStruct? _currentNation;

  void _interactTerrain(TileMapTerrain terrain) async {
    await engine.invoke('handleWorldTerrainInteraction',
        positionalArgs: [terrain.left, terrain.top]);
  }

  void _enterLocation(String locationId) async {
    final locationData =
        engine.invoke('getLocationById', positionalArgs: [locationId]);
    await engine
        .invoke('onHeroEnteredLocation', positionalArgs: [locationData]);
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => LocationView(locationData: locationData),
    );
  }

  void _mapTapHandler(GameEvent event) {
    final e = event as MapInteractionEvent;
    if (engine.isOnDesktop) {
      if (e.buttons & kPrimaryButton == kPrimaryButton) {
        if (_menuPosition != null) {
          _menuPosition = null;
        } else {
          final hero = _scene.map.hero;
          if (hero == null) return;
          if (hero.isMoving) return;
          final terrain = _scene.map.selectedTerrain;
          if (terrain == null) return;
          List<int>? route;
          if (terrain.tilePosition != hero.tilePosition) {
            final start = engine.invoke('getTerrain',
                positionalArgs: [hero.left, hero.top, _scene.worldData]);
            final end = engine.invoke('getTerrain',
                positionalArgs: [terrain.left, terrain.top, _scene.worldData]);
            List? calculatedRoute = engine.invoke('calculateRoute',
                positionalArgs: [start, end, _scene.worldData]);
            if (calculatedRoute != null) {
              route = List<int>.from(calculatedRoute);
              if (terrain.locationId != null) {
                _scene.map.moveHeroToTilePositionByRoute(
                  route,
                  onDestinationCallback: () =>
                      _enterLocation(terrain.locationId!),
                );
              } else {
                _scene.map.moveHeroToTilePositionByRoute(route);
              }
            }
          } else {
            if (terrain.locationId != null) {
              _enterLocation(terrain.locationId!);
            }
          }
        }
      } else if (e.buttons & kSecondaryButton == kSecondaryButton) {
        if (_scene.map.hero?.isMoving ?? false) return;
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
    engine.invoke('build', positionalArgs: [context]);

    engine.hetu.interpreter.bindExternalFunction(
        'showWorldMapGameOver',
        (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            showDialog(
              context: context,
              builder: (BuildContext context) => const GameOver(),
            ),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'setWorldMapEntity',
        (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            _scene.map.setTerrainEntity(
                positionalArgs[0], positionalArgs[1], positionalArgs[2]),
        override: true);

    engine.registerListener(
      Events.mapTapped,
      EventHandler(widget.key!, _mapTapHandler),
    );

    // engine.registerListener(
    //   Events.mapDoubleTapped,
    //   EventHandler(widget.key!, _mapTapHandler),
    // );

    // engine.registerListener(
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

    engine.registerListener(
      Events.loadedMap,
      EventHandler(
        widget.key!,
        (GameEvent event) async {
          if ((event as MapLoadedEvent).isNewGame) {
            final charactersData = engine.invoke('getCharacters');
            final characterIds = <String>[];
            for (final characterData in charactersData) {
              final age = engine
                  .invoke('getCharacterAge', positionalArgs: [characterData]);
              if (age >= kMinHeroAge && age < kMaxHeroAge) {
                characterIds.add(characterData['id']);
              }
            }
            final key = await CharacterSelectDialog.show(
              context: context,
              title: engine.locale['selectHero'],
              characterIds: characterIds,
              showCloseButton: false,
            );
            engine.invoke('setHeroId', positionalArgs: [key]);
            engine.invoke('onGameEvent', positionalArgs: ['onNewGame']);
          }
          _heroData = engine.invoke('getHero');
          final charSheet = SpriteSheet(
            image: await Flame.images.load('character/tile_character.png'),
            srcSize: heroSrcSize,
          );
          final shipSheet = SpriteSheet(
            image: await Flame.images.load('character/tile_ship.png'),
            srcSize: heroSrcSize,
          );
          _scene.map.hero = TileMapObject(
            engine: engine,
            sceneKey: _scene.key,
            isHero: true,
            animationSpriteSheet: charSheet,
            waterAnimationSpriteSheet: shipSheet,
            left: _heroData!['worldPosition']['left'],
            top: _heroData!['worldPosition']['top'],
            tileShape: _scene.map.tileShape,
            tileMapWidth: _scene.map.tileMapWidth,
            gridWidth: _scene.map.gridWidth,
            gridHeight: _scene.map.gridHeight,
            srcWidth: heroSrcSize.x,
            srcHeight: heroSrcSize.y,
          );
          currentTerrain = _scene.map.getTerrain(
              _heroData!['worldPosition']['left'],
              _heroData!['worldPosition']['top']);

          setState(() {});
        },
      ),
    );

    engine.registerListener(
      Events.heroMoved,
      EventHandler(
        widget.key!,
        (GameEvent event) {
          final heroEvent = event as HeroEvent;
          if (heroEvent.scene == 'worldmap') {
            engine.invoke('setHeroPosition', positionalArgs: [
              heroEvent.tilePosition.left,
              heroEvent.tilePosition.top,
            ]);

            engine.invoke('updateGame');
            currentTerrain = _scene.map.getTerrainAtHero();
            final bool blocked = engine.invoke('onHeroMovedOnWorldMap',
                positionalArgs: [
                  heroEvent.tilePosition.left,
                  heroEvent.tilePosition.top
                ]);
            if (blocked) {
              _scene.map.hero!.isMovingCanceled = true;
            }
          }
          setState(() {});
        },
      ),
    );

    engine.registerListener(
      CustomEvents.needRebuildUI,
      EventHandler(
        widget.key!,
        (GameEvent event) {
          updateInfoPanels();
        },
      ),
    );

    // FlameAudio.bgm.play('music/chinese-oriental-tune-06-12062.mp3');
  }

  @override
  void dispose() {
    engine.disposeListenders(widget.key!);
    // FlameAudio.bgm.stop();
    // FlameAudio.bgm.dispose();

    _scene.detach();
    super.dispose();
  }

  void updateInfoPanels() {
    if (_heroData != null) {
      _questData =
          engine.invoke('getCharacterActiveQuest', positionalArgs: [_heroData]);
    }
    if (mounted) setState(() {});
  }

  Future<Scene?> _getScene(Map<String, dynamic> args) async {
    if (_isDisposing) return null;
    final scene =
        await engine.createScene('worldmap', args['id'], args) as WorldMapScene;
    _heroData = engine.invoke('getHero');
    updateInfoPanels();
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // pass the build context to script
    // final screenSize = MediaQuery.of(context).size;

    // ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return FutureBuilder(
      // 不知道为啥，这里必须用这种写法才能进入载入界面，否则一定会卡住
      future: Future.delayed(
        const Duration(milliseconds: 100),
        () => _getScene(widget.args),
      ),
      builder: (context, snapshot) {
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
                child: HeroInfoPanel(
                  heroData: _heroData!,
                  currentTerrain: _currentTerrain,
                  currentNationData: _currentNation,
                  currentLocationData: _currentLocation,
                ),
              ),
            if (_questData != null)
              Positioned(
                left: 300,
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
                      _scene.map.gridMode = GridMode.none;
                      break;
                    case WorldMapDropMenuItems.viewZones:
                      _scene.map.gridMode = GridMode.zone;
                      break;
                    case WorldMapDropMenuItems.viewNations:
                      _scene.map.gridMode = GridMode.nation;
                      break;
                    case WorldMapDropMenuItems.console:
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => const Console(),
                      ).then((_) => setState(() {}));
                      break;
                    case WorldMapDropMenuItems.exit:
                      _saveGame().then((_) {
                        _isDisposing = true;
                        engine.leaveScene(_scene.id, clearCache: true);
                        engine.invoke('resetGame');
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
              final terrainZone = _scene.map.zones[selectedTerrain.zoneIndex];
              final characters = _scene.map.selectedActors;
              final hero = _scene.map.hero;
              List<int>? route;
              var isTappingHeroPosition = false;
              if (hero != null) {
                isTappingHeroPosition =
                    selectedTerrain.tilePosition == hero.tilePosition;
                if (!isTappingHeroPosition) {
                  final start = engine.invoke('getTerrain',
                      positionalArgs: [hero.left, hero.top, _scene.worldData]);
                  final end = engine.invoke('getTerrain', positionalArgs: [
                    selectedTerrain.left,
                    selectedTerrain.top,
                    _scene.worldData
                  ]);
                  List? calculatedRoute = engine.invoke('calculateRoute',
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

              final stringBuffer = StringBuffer();
              stringBuffer.writeln(
                  '坐标: ${selectedTerrain.left}, ${selectedTerrain.top}');

              final zoneData = engine.invoke('getZoneByIndex',
                  positionalArgs: [selectedTerrain.zoneIndex]);
              final zoneName = zoneData['name'];
              if (zoneName != null) {
                stringBuffer.writeln(zoneName);
              }

              if (selectedTerrain.nationId != null) {
                final nationData = engine.invoke('getNationById',
                    positionalArgs: [selectedTerrain.nationId]);
                stringBuffer.writeln('${nationData['name']}');
              }

              if (selectedTerrain.locationId != null) {
                final locationData = engine.invoke('getLocationById',
                    positionalArgs: [selectedTerrain.locationId]);
                stringBuffer.writeln('${locationData['name']}');
              }

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
                  interactIcon: terrainZone.index != 0,
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
                  enterIcon:
                      ((route != null && selectedTerrain.locationId != null) ||
                              (isTappingHeroPosition &&
                                  selectedTerrain.locationId != null))
                          ? true
                          : false,
                  onEnter: () {
                    if (route != null) {
                      _scene.map.moveHeroToTilePositionByRoute(
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
                  description: stringBuffer.toString(),
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
    var savePath = engine.invoke('getSavePath');
    if (savePath == null) {
      final worldId = engine.invoke('getWorldId');
      final directory = await path.getApplicationDocumentsDirectory();
      savePath = path.join(directory.path, 'Heavenly Tribulation', 'save',
          worldId + kWorldSaveFileExtension);
      engine.invoke('setSavePath', positionalArgs: [savePath]);
    }
    engine.info('保存游戏至：[$savePath]');
    final saveFile = File(savePath);
    if (!saveFile.existsSync()) {
      saveFile.createSync(recursive: true);
    }
    final gameJsonData = engine.invoke('getGameJsonData');
    gameJsonData['world']['isNewGame'] = false;
    final gameStringData = jsonEncodeWithIndent(gameJsonData);
    saveFile.writeAsStringSync(gameStringData);

    final saveFile2 = File(savePath + '2');
    if (!saveFile2.existsSync()) {
      saveFile2.createSync(recursive: true);
    }
    final historyJsonData = engine.invoke('getHistoryJsonData');
    final historyStringData = jsonEncodeWithIndent(historyJsonData);
    saveFile2.writeAsStringSync(historyStringData);
  }
}
