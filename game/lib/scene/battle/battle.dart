import 'package:flutter/material.dart' hide Card;
import 'package:samsara/samsara.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/event.dart';
// import 'package:samsara/widgets.dart';
// import 'package:samsara/cardgame/cardgame.dart';
import 'package:hetu_script/utils/uid.dart';
// import 'package:samsara/task.dart';
import 'package:samsara/cardgame/card.dart';

import '../../config.dart';
import 'components/battle.dart';
import 'drop_menu.dart';
// import '../../avatar.dart';

class BattleSceneOverlay extends StatefulWidget {
  const BattleSceneOverlay({
    required super.key,
    required this.heroData,
    required this.enemyData,
    required this.heroCards,
    required this.enemyCards,
    required this.isSneakAttack,
  });

  final dynamic heroData, enemyData;
  final List<GameCard> heroCards, enemyCards;

  final bool isSneakAttack;

  @override
  State<BattleSceneOverlay> createState() => _BattleSceneOverlayState();
}

class _BattleSceneOverlayState extends State<BattleSceneOverlay> {
  // late Animation<double> battleStartBannerAnimation, battleEndBannerAnimation;
  // late AnimationController battleStartBannerAnimationController,
  //     battleEndBannerAnimationController;

  late BattleScene _scene;

  void close() {
    _scene.leave(clearCache: true);
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();

    // FlameAudio.bgm.initialize();

    engine.addEventListener(
      'battleEnded',
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, args, scene) => close(),
      ),
    );

    // engine.bgm.initialize();
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    _scene.detach();
    super.dispose();
  }

  Future<Scene?> _getScene() async {
    final id = 'cardgame_${randomUID()}';
    final scene = await engine.createScene(
      contructorKey: 'cardGame',
      sceneId: id,
      arg: {
        'id': id,
        'heroData': widget.heroData,
        'enemyData': widget.enemyData,
        'heroCards': widget.heroCards,
        'enemyCards': widget.enemyCards,
        'isSneakAttack': widget.isSneakAttack,
      },
    );
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    // ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return FutureBuilder(
      // 不知道为啥，这里必须用这种写法才能进入载入界面，否则一定会卡住
      future: Future.delayed(
        const Duration(milliseconds: 100),
        () => _getScene(),
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
          _scene = snapshot.data as BattleScene;
          if (_scene.isAttached) {
            _scene.detach();
          }
          return Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                SceneWidget(scene: _scene),
                // if (_scene.isLoading)
                //   LoadingScreen(text: engine.locale('loading')),
                // Positioned(
                //   height: 150,
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Padding(
                //         padding: const EdgeInsets.only(right: 5.0),
                //         child: Avatar(
                //           size: const Size(120, 120),
                //           // name: widget.heroData['name'],
                //           image: AssetImage(
                //               'assets/images/avatar/${widget.heroData['icon']}'),
                //           borderColor: kBackgroundColor,
                //         ),
                //       ),
                //       Image.asset('assets/images/battle/versus.png'),
                //       Padding(
                //         padding: const EdgeInsets.only(left: 5.0),
                //         child: Avatar(
                //           size: const Size(120, 120),
                //           // name: widget.enemyData['name'],
                //           image: AssetImage(
                //               'assets/images/avatar/${widget.enemyData['icon']}'),
                //           borderColor: kBackgroundColor,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: BattleDropMenu(
                    onSelected: (BattleDropMenuItems item) async {
                      switch (item) {
                        case BattleDropMenuItems.console:
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => Console(
                              engine: engine,
                            ),
                          ).then((_) => setState(() {}));
                        case BattleDropMenuItems.quit:
                          close();
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
