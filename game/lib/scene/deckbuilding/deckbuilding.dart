import 'package:flutter/material.dart' hide Card;
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/ui/label.dart';
// import 'package:samsara/event.dart';
import 'package:samsara/cardgame/card.dart';

import '../../dialog/game_dialog/game_dialog.dart';
import '../battle/battle.dart';
import '../../config.dart';
import 'components/deckbuilding.dart';
import 'drop_menu.dart';

class DeckBuildingOverlay extends StatefulWidget {
  final int deckSize;

  final dynamic heroData, enemyData;

  final Iterable<String> heroLibrary;
  final List<Card>? enemyDeck;

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

class _DeckBuildingOverlayState extends State<DeckBuildingOverlay> {
  late DeckBuildingScene _scene;

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    _scene.detach();
    super.dispose();
  }

  // @override
  // void initState() {
  //   super.initState();

  // engine.addEventListener(
  //   'cardFocused',
  //   EventHandler(
  //     widgetKey: widget.key!,
  //     handle: (eventId, args, scene) {},
  //   ),
  // );
  // }

  Future<Scene?> _getScene() async {
    final scene = await engine.createScene(
      contructorKey: 'deckBuilding',
      sceneId: 'deckBuilding',
      arg: widget.heroLibrary,
    ) as DeckBuildingScene;
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
          _scene = snapshot.data as DeckBuildingScene;
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
                              'lines': [
                                engine
                                    .locale('deckbuilding.requiredCardsPrompt')
                              ],
                            },
                          );
                        } else {
                          _scene.leave(clearCache: true);
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
                          ).then((value) {
                            engine.bgm.resume();
                          });
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
                  right: 0,
                  top: 0,
                  child: DeckbuildingDropMenu(
                    onSelected: (DeckbuildingDropMenuItems item) async {
                      switch (item) {
                        case DeckbuildingDropMenuItems.console:
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => Console(
                              engine: engine,
                            ),
                          ).then((_) => setState(() {}));
                        case DeckbuildingDropMenuItems.quit:
                          _scene.leave(clearCache: true);
                          Navigator.of(context).pop();
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
