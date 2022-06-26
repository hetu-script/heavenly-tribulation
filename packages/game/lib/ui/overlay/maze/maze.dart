import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:hetu_script/values.dart';

// import '../../../../ui/shared/avatar.dart';
import '../../shared/loading_screen.dart';
import '../../../global.dart';
import '../../../scene/maze.dart';
import 'drop_menu.dart';
import '../../view/console.dart';

class MazeOverlay extends StatefulWidget {
  const MazeOverlay({
    required super.key,
    this.data,
    this.startLevel = 0,
  });

  final List<dynamic>? data;

  final int startLevel;

  @override
  State<MazeOverlay> createState() => _MazeOverlayState();
}

class _MazeOverlayState extends State<MazeOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late MazeScene _scene;

  late int _currentLevel;

  // late final HTStruct _heroData;

  @override
  void initState() {
    super.initState();

    engine.invoke('build', positionalArgs: [context]);
    _currentLevel = widget.startLevel;
    // _heroData = engine.invoke('getHero');

    engine.registerListener(
      Events.mapTapped,
      EventHandler(
        widget.key!,
        (event) {
          final hero = _scene.map.hero;
          if (hero.isMoving) return;
          final terrain = _scene.map.selectedTerrain;
          if (terrain == null) return;
          if (terrain.isVoid) return;
          List<int>? route;
          if (terrain.tilePosition != hero.tilePosition) {
            final start = engine.invoke('getTerrain',
                positionalArgs: [hero.left, hero.top, _scene.data]);
            final end = engine.invoke('getTerrain',
                positionalArgs: [terrain.left, terrain.top, _scene.data]);
            List? calculatedRoute = engine.invoke('calculateRoute',
                positionalArgs: [start, end, _scene.data]);
            if (calculatedRoute != null) {
              route = List<int>.from(calculatedRoute);
              _scene.map.moveHeroToTilePositionByRoute(route);
            }
          }
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
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    late final List<dynamic> data = widget.data ??
        ModalRoute.of(context)!.settings.arguments as List<dynamic>;

    return FutureBuilder(
      // 不知道为啥，这里必须用这种写法才能进入载入界面，否则一定会卡住
      future: Future.delayed(
        const Duration(milliseconds: 100),
        () => _createLevel(data[_currentLevel]),
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
              ],
            ),
          );
        }
      },
    );
  }
}
