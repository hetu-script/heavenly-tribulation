import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:heavenly_tribulation/ui/view/information/information.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:flame_audio/flame_audio.dart';

import 'popup.dart';
import '../../../shared/json.dart';
import '../../../shared/constants.dart';
import '../../../shared/util.dart';
import 'history_panel.dart';
import '../../shared/loading_screen.dart';
import '../../../global.dart';
import '../../../scene/worldmap.dart';
import 'character_info.dart';
import 'drop_menu.dart';
import '../../view/console.dart';

class WorldMapOverlay extends StatefulWidget {
  final WorldMapScene scene;

  const WorldMapOverlay({required super.key, required this.scene});

  @override
  State<WorldMapOverlay> createState() => _WorldMapOverlayState();
}

class _WorldMapOverlayState extends State<WorldMapOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  WorldMapScene get scene => widget.scene;
  TileMap get map => widget.scene.map!;

  Vector2? menuPosition;

  @override
  void initState() {
    super.initState();

    engine.registerListener(
      Events.loadedMap,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    engine.registerListener(
      Events.tappedMap,
      EventHandler(widget.key!, (event) {
        if (map.hero!.isMoving) {
          return;
        }
        setState(() {
          final terrain = (event as MapInteractionEvent).terrain;
          if (terrain != null) {
            final tilePos = terrain.tilePosition;
            menuPosition = scene.map!
                .tilePosition2TileCenterInScreen(tilePos.left, tilePos.top);
          }
        });
      }),
    );

    FlameAudio.bgm.play('music/chinese-oriental-tune-06-12062.mp3');
  }

  @override
  void dispose() {
    super.dispose();
    engine.disposeListenders(widget.key!);
    FlameAudio.bgm.stop();
    FlameAudio.bgm.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // pass the build context to script
    engine.invoke('build', positionalArgs: [context]);

    final heroData = engine.invoke('getHero');
    final screenSize = MediaQuery.of(context).size;

    final screenWidgets = [
      SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: SceneWidget(scene: scene),
      ),
      if (heroData != null)
        Positioned(
          left: 0,
          top: 0,
          child: HeroInfoPanel(heroData: heroData),
        ),
      Positioned(
        right: 0,
        top: 0,
        child: DropMenu(
          onSelected: (DropMenuItems item) {
            switch (item) {
              case DropMenuItems.info:
                showDialog(
                    context: context,
                    builder: (context) => const InformationPanel());
                break;
              case DropMenuItems.viewNone:
                map.gridMode = GridMode.none;
                break;
              case DropMenuItems.viewZones:
                map.gridMode = GridMode.zone;
                break;
              case DropMenuItems.viewNations:
                map.gridMode = GridMode.nation;
                break;
              case DropMenuItems.console:
                showDialog(
                  context: context,
                  builder: (BuildContext context) => const Console(),
                );
                break;
              case DropMenuItems.exit:
                engine.leaveScene('WorldMap');
                _saveGame();
                engine.broadcast(const GameEvent.back2Menu());
                break;
              default:
            }
          },
        ),
      ),
      Positioned(
        left: 0,
        bottom: 0,
        child: HistoryPanel(key: UniqueKey()),
      ),
    ];

    if (menuPosition != null) {
      if (map.selectedTerrain != null) {
        final terrain = map.selectedTerrain!;
        final terrainZone = map.zones[terrain.zoneIndex];
        final characters = map.selectedActors;
        final hero = map.hero;
        List<int>? route;
        var isHeroPosition = false;
        if (terrain.tilePosition != hero!.tilePosition) {
          final start = engine.hetu.interpreter
              .invoke('getTerrain', positionalArgs: [hero.left, hero.top]);
          final end = engine.invoke('getTerrain',
              positionalArgs: [terrain.left, terrain.top]);
          List? calculatedRoute = engine.hetu.interpreter
              .invoke('calculateRoute', positionalArgs: [start, end]);
          if (calculatedRoute != null) {
            route = List<int>.from(calculatedRoute);
            // for (var i = 1; i < route.length; ++i) {
            //   final index = route[i];
            //   final tilePosition = map.index2TilePos(index);
            //   engine.info(tilePosition);
            // }
          }
        } else {
          isHeroPosition = true;
        }

        void closePopup() {
          setState(() {
            menuPosition = null;
            scene.map!.selectedTerrain = null;
          });
        }

        final stringBuffer = StringBuffer();

        stringBuffer.writeln('坐标: ${terrain.left}, ${terrain.top}');

        final zoneData = engine.hetu.interpreter
            .invoke('getZoneByIndex', positionalArgs: [terrain.zoneIndex]);
        stringBuffer.writeln('${zoneData['name']}');

        if (terrain.nationId != null) {
          final nationData = engine.hetu.interpreter
              .invoke('getNationById', positionalArgs: [terrain.nationId]);
          stringBuffer.writeln('${nationData['name']}');
        }

        if (terrain.locationId != null) {
          final locationData = engine.hetu.interpreter
              .invoke('getLocationById', positionalArgs: [terrain.locationId]);
          stringBuffer.writeln('${locationData['name']}');
        }

        screenWidgets.add(
          WorldMapPopup(
            left: menuPosition!.x - WorldMapPopup.defaultSize / 2,
            top: menuPosition!.y - WorldMapPopup.defaultSize / 2,
            onPanelTapped: closePopup,
            moveToIcon: route != null,
            onMoveToIconTapped: () {
              map.moveHeroToTilePositionByRoute(route!);
              closePopup();
            },
            checkIcon: terrainZone.index != 0,
            onCheckIconTapped: () {
              if (route != null) {
                map.moveHeroToTilePositionByRoute(route,
                    action: DestinationAction.check);
              } else {
                engine.broadcast(
                    MapInteractionEvent.checkTerrain(terrain: terrain));
              }
              closePopup();
            },
            enterIcon: ((route != null && terrain.locationId != null) ||
                    (isHeroPosition && terrain.locationId != null))
                ? true
                : false,
            onEnterIconTapped: () {
              if (route != null) {
                map.moveHeroToTilePositionByRoute(route,
                    action: DestinationAction.enter);
              } else {
                engine.broadcast(
                    LocationEvent.entered(locationId: terrain.locationId!));
              }
              closePopup();
            },
            talkIcon: characters != null ? true : false,
            onTalkIconTapped: closePopup,
            restIcon: isHeroPosition,
            onRestIconTapped: closePopup,
            title: stringBuffer.toString(),
          ),
        );
      }
    }

    if (!widget.scene.isMapReady) {
      screenWidgets.add(LoadingScreen(text: engine.locale['loading']));
    }

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: Stack(
          children: screenWidgets,
        ),
      ),
    );
  }

  Future<void> _saveGame() async {
    var savePath = engine.invoke('getSavePath');
    if (savePath == null) {
      final stampName = timestampCrc();
      final directory = await path.getApplicationDocumentsDirectory();
      savePath = path.join(directory.path, 'Heavenly Tribulation', 'save',
          stampName + kWorldSaveFileExtension);
      engine.invoke('setSavePath', positionalArgs: [savePath]);
    }
    engine.info('保存游戏至：[$savePath]');
    final saveFile = File(savePath);
    if (!saveFile.existsSync()) {
      saveFile.createSync(recursive: true);
    }
    final gameJsonData = engine.invoke('getGameJsonData');
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
