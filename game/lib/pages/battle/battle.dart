import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:samsara/ui/flutter/loading_screen.dart';
import 'package:samsara/event.dart';
import 'package:samsara/event/cardgame.dart';
// import 'package:samsara/widgets.dart';
// import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/console.dart';
import 'package:samsara/utils/uid.dart';
// import 'package:samsara/task.dart';
import 'package:samsara/cardgame/playing_card.dart';

import '../../config.dart';
import 'scene/battle.dart';
import '../deckbuilding/drop_menu.dart';
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
  final List<PlayingCard> heroCards, enemyCards;

  final bool isSneakAttack;

  @override
  State<BattleSceneOverlay> createState() => _BattleSceneOverlayState();
}

class _BattleSceneOverlayState extends State<BattleSceneOverlay>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  // late Animation<double> battleStartBannerAnimation, battleEndBannerAnimation;
  // late AnimationController battleStartBannerAnimationController,
  //     battleEndBannerAnimationController;

  late BattleScene _scene;

  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();

    // FlameAudio.bgm.initialize();

    engine.addEventListener(
      CardGameEvents.battleEnded,
      EventHandler(
        ownerKey: widget.key!,
        handle: (event) {
          final result = (event as CardGameEvent).heroWon ?? false;
          Navigator.of(context).maybePop(result);
          engine.info('战斗结束：${result ? '胜利' : '失败'}');
        },
      ),
    );

    engine.bgm.initialize();
    // engine.bgm
    //     .play('music/war-drums-173853.mp3', volume: GameConfig.musicVolume);
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    // engine.bgm.stop();
    // engine.bgm.dispose();

    _scene.detach();
    super.dispose();
  }

  Future<Scene?> _getScene() async {
    if (_isDisposing) return null;
    final id = 'cardGame${uid(4)}';
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
    ) as BattleScene;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return _isDisposing
        ? LoadingScreen(text: engine.locale['loading'])
        : FutureBuilder(
            // 不知道为啥，这里必须用这种写法才能进入载入界面，否则一定会卡住
            future: Future.delayed(
              const Duration(milliseconds: 100),
              () => _getScene(),
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                throw (snapshot.error!);
              }

              if (!snapshot.hasData) {
                return LoadingScreen(text: engine.locale['loading']);
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
                      if (_scene.isLoading)
                        LoadingScreen(text: engine.locale['loading']),
                      SceneWidget(scene: _scene),
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
                        child: CardGameDropMenu(
                          onSelected: (CardGameDropMenuItems item) async {
                            switch (item) {
                              case CardGameDropMenuItems.console:
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => Console(
                                    engine: engine,
                                  ),
                                ).then((_) => setState(() {}));
                                break;
                              case CardGameDropMenuItems.quit:
                                engine.leaveScene(_scene.id, clearCache: true);
                                _isDisposing = true;
                                // Task.clearAll();
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
