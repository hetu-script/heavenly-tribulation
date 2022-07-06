import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:hetu_script/values.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:hetu_script/types.dart';

import '../../shared/loading_screen.dart';
import '../../../global.dart';
import '../../../scene/maze.dart';
import 'drop_menu.dart';
import '../../view/console.dart';
import '../hero_info.dart';
import '../history_panel.dart';
import '../../../event/events.dart';

class MazeOverlay extends StatefulWidget {
  const MazeOverlay({
    required super.key,
    this.mazeData,
    this.startLevel = 0,
  });

  final HTStruct? mazeData;

  final int startLevel;

  @override
  State<MazeOverlay> createState() => _MazeOverlayState();
}

class _MazeOverlayState extends State<MazeOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late MazeScene _scene;

  HTStruct? _heroData;

  late int _currentLevelIndex;

  // late final HTStruct _heroData;

  @override
  void initState() {
    super.initState();

    engine.invoke('build', positionalArgs: [context]);
    _currentLevelIndex = widget.startLevel;
    // _heroData = engine.invoke('getHero');

    engine.hetu.interpreter.bindExternalFunction(
        'moveHeroToLastRouteNode',
        (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            _scene.map.moveHeroToLastRouteNode(),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'setFogOfWar',
        (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            _scene.map.showFogOfWar = positionalArgs.first,
        override: true);

    engine.registerListener(
      Events.mapTapped,
      EventHandler(
        widget.key!,
        (event) {
          final hero = _scene.map.hero;
          if (hero == null) return;
          if (hero.isMoving) return;
          final terrain = _scene.map.selectedTerrain;
          if (terrain == null) return;
          List<int>? route;
          if (terrain.tilePosition != hero.tilePosition) {
            final start = engine.invoke('getTerrain',
                positionalArgs: [hero.left, hero.top, _scene.mapData]);
            final end = engine.invoke('getTerrain',
                positionalArgs: [terrain.left, terrain.top, _scene.mapData]);
            List? calculatedRoute = engine.invoke('calculateRoute',
                positionalArgs: [start, end, _scene.mapData],
                namedArgs: {'restrictedInZoneIndex': start['zoneIndex']});
            if (calculatedRoute != null) {
              route = List<int>.from(calculatedRoute);
              _scene.map.moveHeroToTilePositionByRoute(route);
            }
          }
        },
      ),
    );

    engine.registerListener(
      Events.loadedMap,
      EventHandler(
        widget.key!,
        (GameEvent event) async {
          final charSheet = SpriteSheet(
            image: await Flame.images.load('character/tile_character.png'),
            srcSize: Vector2(32.0, 32.0),
          );
          final shipSheet = SpriteSheet(
            image: await Flame.images.load('character/tile_ship.png'),
            srcSize: Vector2(32.0, 32.0),
          );
          _scene.map.hero = TileMapObject(
            engine: engine,
            sceneKey: _scene.key,
            isHero: true,
            animationSpriteSheet: charSheet,
            waterAnimationSpriteSheet: shipSheet,
            left: _scene.mapData['entryX'],
            top: _scene.mapData['entryY'],
            tileShape: _scene.map.tileShape,
            tileMapWidth: _scene.map.tileMapWidth,
            gridWidth: _scene.map.gridWidth,
            gridHeight: _scene.map.gridHeight,
            srcWidth: 32,
            srcHeight: 32,
          );
          setState(() {});
        },
      ),
    );

    engine.registerListener(
      Events.heroMoved,
      EventHandler(
        widget.key!,
        (GameEvent event) async {
          final currentTile = _scene.map.getTerrainAtHero()!;
          if (currentTile.object != null) {
            final String? entityId = currentTile.object!.entityId;
            if (entityId != null) {
              if (_scene.map.hero != null) {
                final blocked = engine.invoke('handleMazeEntityInteraction',
                    positionalArgs: [entityId, widget.mazeData]);
                if (blocked) {
                  _scene.map.moveHeroToLastRouteNode();
                } else {
                  _scene.map.hero!.isMovingCanceled = true;
                }
              }
            }
          }
          setState(() {});
        },
      ),
    );

    engine.registerListener(
      CustomEvents.dialogFinished,
      EventHandler(
        widget.key!,
        (GameEvent event) {
          setState(() {});
        },
      ),
    );
  }

  @override
  void dispose() {
    engine.disposeListenders(widget.key!);
    // FlameAudio.bgm.stop();
    // FlameAudio.bgm.dispose();

    _scene.detach();
    super.dispose();
  }

  Future<Scene> _createLevel(HTStruct levelData) async {
    final scene = await engine.createScene('maze', levelData) as MazeScene;
    _heroData = engine.invoke('getHero');
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    late final HTStruct data = widget.mazeData ??
        ModalRoute.of(context)!.settings.arguments as HTStruct;

    return FutureBuilder(
      // 不知道为啥，这里必须用这种写法才能进入载入界面，否则一定会卡住
      future: Future.delayed(
        const Duration(milliseconds: 100),
        () => _createLevel(data['levels'][_currentLevelIndex]),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingScreen(text: engine.locale['loading']);
        } else {
          _scene = snapshot.data as MazeScene;
          if (_scene.isAttached) {
            _scene.detach();
          }
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                SceneWidget(scene: _scene),
                if (_heroData != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: HeroInfoPanel(heroData: _heroData!),
                  ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: MazeDropMenu(
                    onSelected: (MazeDropMenuItems item) async {
                      switch (item) {
                        case MazeDropMenuItems.console:
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => const Console(),
                          ).then((value) => setState(() {}));
                          break;
                        case MazeDropMenuItems.quit:
                          engine.leaveScene('maze');
                          Navigator.of(context).pop();
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
                    historyData: widget.mazeData?['history'],
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
