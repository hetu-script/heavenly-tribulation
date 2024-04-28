import 'package:flutter/material.dart' hide Card;
import 'package:heavenly_tribulation/events.dart';
import 'package:samsara/event.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/loading_screen.dart';
// import 'package:samsara/ui/label.dart';
// import 'package:samsara/event.dart';
// import 'package:samsara/cardgame/card.dart';

// import '../../dialog/game_dialog/game_dialog.dart';
import '../../config.dart';
import 'components/cultivation.dart';
import 'drop_menu.dart';
import '../history_info.dart';
import '../hero_info.dart';
import '../../view/character/cardpacks.dart';

class CultivationOverlay extends StatefulWidget {
  final dynamic heroData;

  CultivationOverlay({required this.heroData}) : super(key: UniqueKey());

  @override
  State<CultivationOverlay> createState() => _CultivationOverlayState();
}

class _CultivationOverlayState extends State<CultivationOverlay> {
  late CultivationScene _scene;

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    _scene.detach();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    engine.addEventListener(
      UIEvents.cardPacksButtonClicked,
      EventHandler(
        widgetKey: widget.key!,
        handle: (id, args, scene) {
          showDialog(
            context: context,
            builder: (context) => CardpacksView(
              characterData: widget.heroData,
            ),
          );
        },
      ),
    );
  }

  Future<Scene?> _getScene() async {
    final scene = await engine.createScene(
      contructorKey: 'cultivation',
      sceneId: 'cultivation',
      arg: widget.heroData,
    ) as CultivationScene;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
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
          return Material(
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
                          engine.bgm.resume();
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
