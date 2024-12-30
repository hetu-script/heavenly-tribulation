import 'package:flutter/material.dart' hide Card;
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/loading_screen.dart';
// import 'package:samsara/event.dart';
// import 'package:samsara/cardgame/card.dart';

// import '../battle/battle.dart';
import '../../engine.dart';
import 'components/library.dart';
import 'drop_menu.dart';

class CardLibraryOverlay extends StatefulWidget {
  final int deckSize;

  CardLibraryOverlay({
    this.deckSize = 4,
  }) : super(key: UniqueKey());

  @override
  State<CardLibraryOverlay> createState() => _CardLibraryOverlayState();
}

class _CardLibraryOverlayState extends State<CardLibraryOverlay> {
  late CardLibraryScene _scene;

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
    ) as CardLibraryScene;
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
          _scene = snapshot.data as CardLibraryScene;
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
                // Positioned(
                //   top: 50,
                //   right: 25,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       // if (_scene.buildingZone.cards.length < widget.deckSize) {
                //       //   GameDialog.show(
                //       //     context: context,
                //       //     dialogData: {
                //       //       'lines': [
                //       //         engine.locale('deckbuilding.requiredCardsPrompt')
                //       //       ],
                //       //     },
                //       //   );
                //       // } else {
                //       //   _scene.leave(clearCache: true);
                //       //   Navigator.of(context).pop(_scene.buildingZone.cards
                //       //       .map((c) => c.clone())
                //       //       .toList());
                //       // }
                //     },
                //     child: const Label(
                //       'Battle!',
                //       width: 120.0,
                //       textAlign: TextAlign.center,
                //     ),
                //   ),
                // ),
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
