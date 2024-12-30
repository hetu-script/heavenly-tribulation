import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:heavenly_tribulation/events.dart';
// import 'package:provider/provider.dart';
import 'package:samsara/event.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/loading_screen.dart';
// import 'package:samsara/ui/label.dart';
// import 'package:samsara/event.dart';
// import 'package:samsara/cardgame/card.dart';
import 'package:provider/provider.dart';

// import '../../dialog/game_dialog/game_dialog.dart';
import '../../engine.dart';
import 'components/cultivation.dart';
import 'drop_menu.dart';
import '../history_info.dart';
import '../hero_info.dart';
// import '../../view/character/cardpacks.dart';
import '../../state/hero.dart';
import '../../state/history.dart';

class CultivationOverlay extends StatefulWidget {
  CultivationOverlay() : super(key: UniqueKey());

  @override
  State<CultivationOverlay> createState() => _CultivationOverlayState();
}

class _CultivationOverlayState extends State<CultivationOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late CultivationScene _scene;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // engine.addEventListener(
    //   UIEvents.cardPacksButtonClicked,
    //   EventHandler(
    //     widgetKey: widget.key!,
    //     handle: (id, args, scene) {
    //       showDialog(
    //         context: context,
    //         builder: (context) => CardpacksView(
    //           characterData: widget.heroData,
    //         ),
    //       );
    //     },
    //   ),
    // );

    engine.addEventListener(
      GameEvents.leaveCultivationScene,
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, sceneId, scene) async {
          _scene.leave();
          Navigator.of(context).pop();
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      engine.hetu.invoke('onEnterCultivation');
    });
  }

  Future<Scene?> _getScene() async {
    final scene = await engine.createScene(
      contructorKey: 'cultivation',
      sceneId: 'cultivation',
    ) as CultivationScene;

    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    context.watch<HeroState>().heroData;
    context.read<HistoryState>().incidents;

    _focusNode.requestFocus();
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
          _scene = snapshot.data as CultivationScene;
          if (_scene.isAttached) {
            _scene.detach();
          }
          return KeyboardListener(
            autofocus: true,
            focusNode: _focusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.space) {
                  _scene.camera.snapTo(Vector2.zero());
                }
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  if (_scene.isLoading)
                    LoadingScreen(text: engine.locale('loading')),
                  SceneWidget(scene: _scene),
                  const Positioned(
                    left: 0,
                    top: 0,
                    child: HeroInfoPanel(),
                  ),
                  const Positioned(
                    left: 0.0,
                    bottom: 0.0,
                    child: HistoryInfoPanel(),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CultivationDropMenu(
                      onSelected: (CultivationDropMenuItems item) async {
                        switch (item) {
                          case CultivationDropMenuItems.console:
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => Console(
                                engine: engine,
                              ),
                            ).then((_) => setState(() {}));
                          case CultivationDropMenuItems.quit:
                            _scene.leave(clearCache: true);
                            Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
