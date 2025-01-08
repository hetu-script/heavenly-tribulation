import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Card;
// import 'package:samsara/lighting/camera2.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/event.dart';
// import 'package:samsara/cardgame/card.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
// import 'package:samsara/components/hovertip.dart';
import 'package:samsara/cardgame/custom_card.dart';

import '../../scene/common.dart';
import '../../scene/events.dart';
// import '../battle/battle.dart';
import '../../engine.dart';
import '../../data.dart';
import 'components/card_library.dart';
// import 'drop_menu.dart';
import '../../view/game_overlay.dart';
import '../../state/windows.dart';
import '../../state/hover_info.dart';
import '../../state/hero.dart';

class CardLibraryOverlay extends StatefulWidget {
  CardLibraryOverlay() : super(key: UniqueKey());

  @override
  State<CardLibraryOverlay> createState() => _CardLibraryOverlayState();
}

class _CardLibraryOverlayState extends State<CardLibraryOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _focusNode = FocusNode();
  // late FocusAttachment _focusAttachment;

  late CardLibraryScene _scene;

  CustomGameCard? _previewingCard;

  dynamic _heroData;

  @override
  void initState() {
    super.initState();

    // _focusAttachment = _focusNode.attach(context);

    _heroData = engine.hetu.fetch('hero');
    assert(_heroData != null);

    engine.addEventListener(
      GameEvents.leaveCardLibrary,
      EventHandler(
        widgetKey: widget.key!,
        callback: (eventId, args, scene) {
          final enemyData = context.read<EnemyState>().enemyData;
          if (enemyData != null) {
            context.read<EnemyState>().show(true);
          }

          context.read<WindowPriorityState>().clearAll();
          _scene.leave();
          Navigator.of(context).pop();
        },
      ),
    );

    engine.addEventListener(
      CardEvents.cardPreview,
      EventHandler(
        widgetKey: widget.key!,
        callback: (eventId, args, scene) {
          _previewingCard = args as CustomGameCard;
          showCardInformation();
        },
      ),
    );

    engine.addEventListener(
      CardEvents.cardUnpreview,
      EventHandler(
        widgetKey: widget.key!,
        callback: (eventId, args, scene) {
          hideCardInformation();
          _previewingCard = null;
        },
      ),
    );
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    _scene.detach();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // _focusAttachment.reparent();
    super.didChangeDependencies();
  }

  void showCardInformation({bool isDetailed = false}) {
    if (_previewingCard == null) return;

    _focusNode.requestFocus();

    final (_, description) = GameData.getDescriptionFromCardData(
      _previewingCard!.data,
      isDetailed: isDetailed,
      characterData: _heroData,
    );

    final position = _scene.camera.localToGlobal(_previewingCard!.position);
    final size = _scene.camera.localToGlobal(_previewingCard!.size);

    context.read<HoverInfoContentState>().set(
        description, Rect.fromLTWH(position.x, position.y, size.x, size.y));

    // Hovertip.show(
    //   scene: _scene,
    //   target: _previewingCard!,
    //   direction: HovertipDirection.rightTop,
    //   content: description,
    //   config: ScreenTextConfig(anchor: Anchor.topCenter),
    // );
  }

  void hideCardInformation() {
    if (_previewingCard == null) return;
    // if (_scene.hoveringComponent is CustomGameCard) return;

    context.read<HoverInfoContentState>().hide();
    // Hovertip.hide(_previewingCard!);
  }

  Future<Scene?> _getScene() async {
    final scene = await engine.createScene(
      contructorKey: kSceneCardLibrary,
      sceneId: kSceneCardLibrary,
    ) as CardLibraryScene;
    return scene;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                KeyboardListener(
                  autofocus: true,
                  focusNode: _focusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                      if (kDebugMode) {
                        print('keydown: ${event.logicalKey.keyLabel}');
                      }
                      switch (event.logicalKey) {
                        case LogicalKeyboardKey.controlLeft:
                        case LogicalKeyboardKey.controlRight:
                          showCardInformation(isDetailed: true);
                      }
                    }
                  },
                  child: SceneWidget(scene: _scene),
                ),
                const Positioned(
                  left: 0,
                  top: 0,
                  child: GameOverlay(sceneId: kSceneCardLibrary),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
