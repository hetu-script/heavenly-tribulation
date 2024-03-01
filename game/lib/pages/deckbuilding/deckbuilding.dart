import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/flutter/loading_screen.dart';
import 'package:samsara/ui/flutter/label.dart';
import 'package:samsara/event.dart';
import 'package:samsara/event/cardgame.dart';
import 'package:samsara/cardgame/playing_card.dart';

import '../../ui/dialog/game_dialog.dart';
import '../battle/battle.dart';
import '../../config.dart';
import 'scene/deckbuilding.dart';

class DeckBuildingOverlay extends StatefulWidget {
  final int deckSize;

  final dynamic heroData, enemyData;

  final List<String> heroLibrary;
  final List<PlayingCard>? enemyDeck;

  DeckBuildingOverlay({
    this.deckSize = 4,
    this.heroData,
    this.enemyData,
    required this.heroLibrary,
    this.enemyDeck,
  }) : super(key: UniqueKey());

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
    _isDisposing = true;

    engine.removeEventListener(widget.key!);

    _scene.detach();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    engine.addEventListener(
      CardGameEvents.cardFocused,
      EventHandler(
        ownerKey: widget.key!,
        handle: (GameEvent e) {},
      ),
    );
  }

  Future<Scene?> _getScene() async {
    if (_isDisposing) return null;
    final scene = await engine.createScene(
      contructorKey: 'deckBuilding',
      sceneId: 'deckBuilding',
      arg: widget.heroLibrary,
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
              if (snapshot.hasError) {
                throw (snapshot.error!);
              }

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
                      if (widget.enemyDeck != null)
                        Positioned(
                          top: 5,
                          right: 100,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_scene.buildingZone.cards.length <
                                  widget.deckSize) {
                                GameDialog.show(
                                  context: context,
                                  dialogData: {
                                    "contents": [
                                      {
                                        // "displayName": "ERROR",
                                        // "icon": "general.png",
                                        "lines": [
                                          engine.locale[
                                              'deckbuilding.requiredCardsPrompt']
                                        ],
                                      },
                                    ],
                                  },
                                );
                              } else {
                                engine.leaveScene(_scene.id, clearCache: true);
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (context) => BattleSceneOverlay(
                                    key: UniqueKey(),
                                    heroData: widget.heroData,
                                    enemyData: widget.enemyData,
                                    heroCards: _scene.buildingZone.cards
                                        .map((c) => c.clone())
                                        .toList(),
                                    enemyCards: widget.enemyDeck!,
                                    isSneakAttack: false,
                                  ),
                                );
                              }
                            },
                            child: const Label(
                              'Battle!',
                              width: 120.0,
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
