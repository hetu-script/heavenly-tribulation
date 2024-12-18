import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:samsara/ui/loading_screen.dart';

import '../../global.dart';
import '../../scene/game.dart';
import 'drop_menu.dart';

class MainGameOverlay extends StatefulWidget {
  MainGameOverlay() : super(key: UniqueKey());

  @override
  State<MainGameOverlay> createState() => _MainGameOverlayState();
}

class _MainGameOverlayState extends State<MainGameOverlay> {
  late GameScene _scene;

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    _scene.detach();
    super.dispose();
  }

  Future<Scene?> _getScene() async {
    final scene = await engine.createScene(
      contructorKey: 'game',
      sceneId: 'game',
    ) as GameScene;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    // pass the build context to script
    // final screenSize = MediaQuery.of(context).size;

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
          _scene = snapshot.data as GameScene;
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
                        case CardGameDropMenuItems.quit:
                          _scene.leave(clearCache: true);
                          Navigator.of(context).pop();
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
