import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/flutter/loading_screen.dart';
import 'package:samsara/ui/flutter/label.dart';

import 'cardgame_autobattler.dart';
import '../../../global.dart';
import '../../../scene/cardgame/deckbuilding/deckbuilding.dart';

class DeckBuildingOverlay extends StatefulWidget {
  const DeckBuildingOverlay({Key? key}) : super(key: key);

  @override
  State<DeckBuildingOverlay> createState() => _DeckBuildingOverlayState();
}

class _DeckBuildingOverlayState extends State<DeckBuildingOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late DeckBuildingScene _scene;

  bool _isDisposing = false;

  @override
  void dispose() {
    // engine.disposeListenders(widget.key!);

    _scene.detach();
    super.dispose();
  }

  Future<Scene?> _getScene() async {
    if (_isDisposing) return null;
    final scene = await engine.createScene(
      'deckBuilding',
      'deckBuilding',
      {
        'basic001': 3,
        'basic002': 3,
        'basic003': 3,
        'basic004': 3,
        'basic005': 3,
      },
    ) as DeckBuildingScene;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                _scene = snapshot.data as DeckBuildingScene;
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
                        top: 5,
                        right: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_scene.deck.pile.isEmpty) return;
                            showDialog(
                              context: context,
                              builder: (context) => CardGameAutoBattlerOverlay(
                                key: UniqueKey(),
                                playerDeck: _scene.deck.pile,
                              ),
                            );
                          },
                          child: const Label(
                            'Test Cardgame',
                            width: 200.0,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: ElevatedButton(
                          onPressed: () {
                            engine.leaveScene(_scene.id, clearCache: true);
                            Navigator.of(context).pop();
                          },
                          child: Label(
                            engine.locale['exit'],
                            textAlign: TextAlign.center,
                          ),
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
