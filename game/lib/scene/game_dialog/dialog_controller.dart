import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../../config.dart';
import '../../state/game_dialog.dart';

const kIllustrationWidth = 600.0;
const kIllustrationHeight = 900.0;

const kBaseIllustrationOffsetY = 150.0;

class GameDialogController extends StatefulWidget {
  const GameDialogController({super.key});

  @override
  State<GameDialogController> createState() => _GameDialogControllerState();
}

class _GameDialogControllerState extends State<GameDialogController>
    with TickerProviderStateMixin {
  late final AnimationController sceneFadeController,
      illustrationFadeController;

  late final Animation<double> sceneFadeAnimation, illustrationFadeAnimation;

  @override
  void initState() {
    super.initState();
    sceneFadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    illustrationFadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    sceneFadeAnimation =
        Tween(begin: 0.0, end: 1.0).animate(sceneFadeController);
    illustrationFadeAnimation =
        Tween(begin: 0.0, end: 1.0).animate(illustrationFadeController);
  }

  @override
  void dispose() {
    sceneFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    final prevScene = context.watch<GameDialogState>().prevScene;
    final sceneInfo = context.watch<GameDialogState>().currentSceneInfo;
    final illustrations = context.watch<GameDialogState>().illustrations;

    Widget? sceneImage;
    if (sceneInfo != null) {
      if (sceneInfo.isFadeIn) {
        sceneFadeController.forward(from: 0.0);
      }

      Widget widget = SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Image(
          image: AssetImage(sceneInfo.path),
          fit: BoxFit.cover,
        ),
      );

      sceneImage = Stack(
        children: [
          if (prevScene != null)
            SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: Image(
                image: AssetImage(prevScene.path),
                fit: BoxFit.cover,
              ),
            ),
          (sceneInfo.isFadeIn && illustrations.isEmpty)
              ? FadeTransition(
                  opacity: sceneFadeAnimation,
                  child: widget,
                )
              : widget,
        ],
      );
    }
    List<Widget> illustrationWidgets = [];

    for (var i = 0; i < illustrations.length; ++i) {
      final info = illustrations.elementAt(i);

      Widget widget = Container(
        width: kIllustrationWidth,
        height: kIllustrationHeight,
        decoration: BoxDecoration(
          image: DecorationImage(
            alignment: Alignment.topCenter,
            image: AssetImage(info.path),
            fit: BoxFit.fitWidth,
          ),
        ),
      );

      // if (i == illustrations.length - 1) {
      //   if (info.isFadeIn) {
      //     illustrationFadeController.forward(from: 0.0);

      //     widget = FadeTransition(
      //       opacity: illustrationFadeAnimation,
      //       child: widget,
      //     );
      //   }
      // }

      illustrationWidgets.add(
        Positioned(
          top: kBaseIllustrationOffsetY + info.offsetY,
          left: (screenSize.width - kIllustrationWidth) / 2 + info.offsetX,
          child: widget,
        ),
      );
    }

    final isEmpty = sceneImage == null && illustrationWidgets.isEmpty;

    return isEmpty
        ? Container()
        : Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                sceneImage!,
                ...illustrationWidgets,
              ],
            ),
          );
  }
}
