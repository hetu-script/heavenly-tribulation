import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_dialog.dart';
import 'game_dialog_content.dart';
import 'selection_dialog.dart';
import '../../game/ui.dart';

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

  String? taskId;

  @override
  void initState() {
    super.initState();
    sceneFadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    illustrationFadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    sceneFadeAnimation =
        Tween(begin: 0.0, end: 1.0).animate(sceneFadeController);
    sceneFadeAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (taskId != null) {
          context.read<GameDialog>().finishTask(taskId!);
          taskId == null;
        }
      }
    });
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
    final prevScene = context.watch<GameDialog>().prevScene;
    final sceneInfo = context.watch<GameDialog>().currentSceneInfo;
    final illustrationsInfo = context.watch<GameDialog>().illustrations;
    final dialogContentData = context.watch<GameDialog>().currentContent;
    final selectionsData = context.watch<GameDialog>().selectionsData;

    Widget? background;
    if (sceneInfo != null) {
      Widget widget = SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Image(
          image: AssetImage(sceneInfo.path),
          fit: BoxFit.cover,
        ),
      );

      if (sceneInfo.isFadeIn &&
          illustrationsInfo.isEmpty &&
          dialogContentData == null &&
          selectionsData == null) {
        sceneFadeController.forward(from: 0.0);
        taskId = sceneInfo.taskId;
        background = Stack(
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
            FadeTransition(
              opacity: sceneFadeAnimation,
              child: widget,
            ),
          ],
        );
      } else {
        taskId = null;
        background = widget;
      }
    } else {
      if (prevScene != null &&
          prevScene.isFadeOut &&
          illustrationsInfo.isEmpty &&
          dialogContentData == null &&
          selectionsData == null) {
        sceneFadeController.reverse(from: 1.0);
        taskId = prevScene.taskId;
        background = FadeTransition(
          opacity: sceneFadeAnimation,
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: Image(
              image: AssetImage(prevScene.path),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        taskId = null;
      }
    }

    List<Widget> illustrations = [];

    for (var i = 0; i < illustrationsInfo.length; ++i) {
      final info = illustrationsInfo.elementAt(i);

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

      // if (i == illustrationsInfo.length - 1) {
      //   if (info.isFadeIn) {
      //     illustrationFadeController.forward(from: 0.0);

      //     widget = FadeTransition(
      //       opacity: illustrationFadeAnimation,
      //       child: widget,
      //     );
      //   }
      // }

      illustrations.add(
        Positioned(
          top: kBaseIllustrationOffsetY + info.offsetY,
          left: (screenSize.width - kIllustrationWidth) / 2 + info.offsetX,
          child: widget,
        ),
      );
    }

    final isEmpty = background == null &&
        illustrations.isEmpty &&
        dialogContentData == null &&
        selectionsData == null;

    return isEmpty
        ? SizedBox.shrink()
        : Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                ModalBarrier(
                  color: GameUI.backgroundColor,
                ),
                if (background != null) background,
                if (illustrations.isNotEmpty) ...illustrations,
                if (dialogContentData != null)
                  GameDialogContent(data: dialogContentData),
                if (selectionsData != null)
                  SelectionDialog(data: selectionsData),
              ],
            ),
          );
  }
}
