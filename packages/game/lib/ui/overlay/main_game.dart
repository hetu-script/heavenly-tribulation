import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:heavenly_tribulation/ui/overlay/quest_info.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
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

  void _enterLocation(String locationId) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => LocationView(
        locationId: locationId,
      ),
    );
  }

  void _mapTapHandler(GameEvent event) {
    final e = event as MapInteractionEvent;
    if (engine.isOnDesktop) {
      if (e.buttons & kPrimaryButton != kPrimaryButton) return;
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
              onDestinationCallback: () => _enterLocation(terrain.locationId!),
            );
          } else {
            _scene.map.moveHeroToTilePositionByRoute(route);
          }
        }
      } else {
        _enterLocation(terrain.locationId!);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    engine.invoke('build', positionalArgs: [context]);

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
      Events.mapDoubleTapped,
      EventHandler(widget.key!, _mapTapHandler),
    );

    engine.registerListener(
      Events.mapTapped,
      EventHandler(widget.key!, (event) {
        final e = event as MapInteractionEvent;
        if (_menuPosition != null) {
          setState(() {
            _menuPosition = null;
          });
        } else if (e.buttons & kSecondaryButton == kSecondaryButton) {
          if (_scene.map.hero?.isMoving ?? false) return;
          setState(() {
            _menuPosition = _scene.map.tilePosition2TileCenterInScreen(
                e.tilePosition.left, e.tilePosition.top);
          });
        }
      }),
    );

    engine.registerListener(
      Events.loadedMap,
      EventHandler(
        widget.key!,
        (GameEvent event) async {
          if ((event as MapLoadedEvent).isNewGame) {
            final charactersData = engine.invoke('getCharacters');
            final characterIds = charactersData.keys;
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
          final positionData = engine
              .invoke('getCharacterWorldPosition', positionalArgs: [_heroData]);
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
            left: positionData['left'],
            top: positionData['top'],
            tileShape: _scene.map.tileShape,
            tileMapWidth: _scene.map.tileMapWidth,
            gridWidth: _scene.map.gridWidth,
            gridHeight: _scene.map.gridHeight,
            srcWidth: heroSrcSize.x,
            srcHeight: heroSrcSize.y,
          );
          setState(() {});
        },
      ),
    );

    engine.registerListener(
      Events.heroMoved,
      EventHandler(
        widget.key!,
        (GameEvent event) {
          setState(() {
            if (event.scene == 'worldmap') {
              engine.invoke('updateGame');
            }
            final tile = _scene.map.getTerrainAtHero();
            if (tile != null) {
              final String? entityId = tile.entityId;
              if (entityId != null) {
                if (_scene.map.hero != null) {
                  final blocked = engine.invoke(
                    'handleWorldMapEntityInteraction',
                    namedArgs: {
                      'entityId': entityId,
                      'left': tile.left,
                      'top': tile.top,
                    },
                  );
                  if (blocked) {
                    _scene.map.hero!.isMovingCanceled = true;
                  }
                }
              }
            }
          });
        },
      ),
    );

    engine.registerListener(
      CustomEvents.needRebuildUI,
      EventHandler(
        widget.key!,
        (GameEvent event) {
          if (!mounted) return;
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
    setState(() {
      if (_heroData != null) {
        _questData = engine
            .invoke('getCharacterActiveQuest', positionalArgs: [_heroData]);
      }
    });
  }

  Future<Scene> _getScene(Map<String, dynamic> args) async {
    final scene =
        await engine.createScene('worldmap', args['id'], args) as WorldMapScene;
    _heroData = engine.invoke('getHero');
    updateInfoPanels();
    engine.hetu.assign('isGameLoaded', true);
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
                child: HeroInfoPanel(characterData: _heroData!),
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
                      ).then((value) => setState(() {}));
                      break;
                    case WorldMapDropMenuItems.exit:
                      _saveGame().then((value) {
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
            Positioned(
              left: 0,
              bottom: 0,
              child: HistoryPanel(
                heroId: _heroData?['id'],
              ),
            ),
          ];

          if (_menuPosition != null) {
            if (_scene.map.selectedTerrain != null) {
              final terrain = _scene.map.selectedTerrain!;
              final terrainZone = _scene.map.zones[terrain.zoneIndex];
              final characters = _scene.map.selectedActors;
              final hero = _scene.map.hero;
              List<int>? route;
              var isTappingHeroPosition = false;
              if (hero != null) {
                isTappingHeroPosition =
                    terrain.tilePosition == hero.tilePosition;
                if (!isTappingHeroPosition) {
                  final start = engine.invoke('getTerrain',
                      positionalArgs: [hero.left, hero.top, _scene.worldData]);
                  final end = engine.invoke('getTerrain', positionalArgs: [
                    terrain.left,
                    terrain.top,
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
              stringBuffer.writeln('坐标: ${terrain.left}, ${terrain.top}');

              final zoneData = engine.invoke('getZoneByIndex',
                  positionalArgs: [terrain.zoneIndex]);
              final zoneName = zoneData['name'];
              if (zoneName != null) {
                stringBuffer.writeln(zoneName);
              }

              if (terrain.nationId != null) {
                final nationData = engine.invoke('getNationById',
                    positionalArgs: [terrain.nationId]);
                stringBuffer.writeln('${nationData['name']}');
              }

              if (terrain.locationId != null) {
                final locationData = engine.invoke('getLocationById',
                    positionalArgs: [terrain.locationId]);
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
                  checkIcon: terrainZone.index != 0,
                  onCheck: () {
                    if (route != null) {
                      _scene.map.moveHeroToTilePositionByRoute(route,
                          onDestinationCallback: () {});
                    } else if (isTappingHeroPosition) {}
                    closePopup();
                  },
                  enterIcon: ((route != null && terrain.locationId != null) ||
                          (isTappingHeroPosition && terrain.locationId != null))
                      ? true
                      : false,
                  onEnter: () {
                    if (route != null) {
                      _scene.map.moveHeroToTilePositionByRoute(
                        route,
                        onDestinationCallback: () =>
                            _enterLocation(terrain.locationId!),
                      );
                    } else if (isTappingHeroPosition) {
                      _enterLocation(terrain.locationId!);
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
