import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:samsara/ui/flutter/loading_screen.dart';
import 'package:samsara/utils/console.dart';

import '../../global.dart';
import '../../scene/game.dart';
import 'drop_menu.dart';

class MainGameOverlay extends StatefulWidget {
  MainGameOverlay() : super(key: UniqueKey());

  @override
  State<MainGameOverlay> createState() => _MainGameOverlayState();
}

class _MainGameOverlayState extends State<MainGameOverlay>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late GameScene _scene;

  bool _isDisposing = false;

  @override
  void dispose() {
    engine.disposeListenders(widget.key!);

    _scene.detach();
    super.dispose();
  }

  Future<Scene?> _getScene() async {
    if (_isDisposing) return null;
    final scene = await engine.createScene('game', 'game') as GameScene;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // pass the build context to script
    // final screenSize = MediaQuery.of(context).size;

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
              if (!snapshot.hasData) {
                return LoadingScreen(text: engine.locale['loading']);
              } else {
                _scene = snapshot.data as GameScene;
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
