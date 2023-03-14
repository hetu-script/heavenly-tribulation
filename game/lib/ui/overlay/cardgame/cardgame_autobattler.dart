import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:samsara/ui/flutter/loading_screen.dart';
import 'package:samsara/event.dart';
import 'package:samsara/widgets.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/utils/console.dart';
import 'package:samsara/utils/uid.dart';
import 'package:samsara/task.dart';

import '../../../global.dart';
import '../../../scene/cardgame/card_battle/card_battle.dart';
import 'drop_menu.dart';

class CardGameAutoBattlerOverlay extends StatefulWidget {
  const CardGameAutoBattlerOverlay({
    required super.key,
    required this.playerDeck,
  });

  final List<String> playerDeck;

  @override
  State<CardGameAutoBattlerOverlay> createState() =>
      _CardGameAutoBattlerOverlayState();
}

class _CardGameAutoBattlerOverlayState extends State<CardGameAutoBattlerOverlay>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late CardBattleScene _scene;

  bool _isDisposing = false;

  PlayingCard? _currentFocusedCardData;

  Animation<double>? drawingCardAnimation;
  AnimationController? drawingCardAnimationController;

  @override
  void initState() {
    super.initState();

    engine.registerListener(
      GameEvents.battleEnded,
      EventHandler(
        ownerKey: widget.key!,
        handle: (event) {
          final result = (event as BattleEvent).heroWon;
          Navigator.of(context).maybePop(result);
          engine.info('战斗结束：${result ? '胜利' : '失败'}');
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

    drawingCardAnimationController?.dispose();

    _scene.detach();
    super.dispose();
  }

  Future<Scene?> _getScene() async {
    if (_isDisposing) return null;
    final id = 'cardGame${uid(4)}';
    final scene = await engine.createScene('cardGame', id, {
      'id': id,
      'playerDeck': widget.playerDeck,
    }) as CardBattleScene;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // pass the build context to script
    // final screenSize = MediaQuery.of(context).size;

    // ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    late String rules;

    if (_currentFocusedCardData != null) {
      final data = _currentFocusedCardData!.data;
      rules = data['rules'] ?? '';
    }

    return _isDisposing
        ? LoadingScreen(text: engine.locale['loading'])
        : FutureBuilder(
            // 不知道为啥，这里必须用这种写法才能进入载入界面，否则一定会卡住
            future: Future.delayed(
              const Duration(milliseconds: 100),
              () => _getScene(),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return LoadingScreen(text: engine.locale['loading']);
              } else {
                _scene = snapshot.data as CardBattleScene;
                if (_scene.isAttached) {
                  _scene.detach();
                }
                return Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      if (_scene.isLoading)
                        LoadingScreen(text: engine.locale['loading']),
                      SceneWidget(scene: _scene),
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
                                Task.clearAll();
                                Navigator.of(context).pop();
                                break;
                              default:
                            }
                          },
                        ),
                      ),
                      if (_currentFocusedCardData != null) ...[
                        // Positioned(
                        //   child: IgnorePointer(
                        //     child: Container(
                        //       width: MediaQuery.of(context).size.width,
                        //       height: MediaQuery.of(context).size.height,
                        //       color: Colors.black45,
                        //     ),
                        //   ),
                        // ),
                        Positioned(
                          right: 40,
                          top: 40,
                          child: IgnorePointer(
                            child: Container(
                              color: Colors.black45,
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SpriteWidget(
                                    sprite:
                                        _currentFocusedCardData!.frontSprite!,
                                    anchor: Anchor.center,
                                    // angle: rotated ? radians(-90) : 0,
                                    // width: width,
                                    // height: height,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(left: 40),
                                    width: 400,
                                    child: Text(rules),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
            },
          );
  }
}
