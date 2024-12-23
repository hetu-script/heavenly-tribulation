import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../../config.dart';
import '../../state/game_dialog.dart';

const kIllustrationWidth = 600.0;
const kIllustrationHeight = 900.0;

class GameDialogController extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
  }) {
    return showDialog<dynamic>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return const GameDialogController();
      },
    );
  }

  const GameDialogController({super.key});

  @override
  State<GameDialogController> createState() => _GameDialogControllerState();
}

class _GameDialogControllerState extends State<GameDialogController>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  late final Animation<double> fadeAnimation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    // TODO: 场景进出的转场效果 + 角色图片的位移效果
    final (scene, prevScene, isFadeIn, isFadeOut) =
        context.watch<GameDialogState>().currentSceneInfo;
    context.read<GameDialogState>().clearFadeInfo();
    if (isFadeIn) {
      controller.forward(from: 0.0);
    } else if (isFadeOut) {
      controller.reverse(from: 1.0);
    }

    final illustrations = context.watch<GameDialogState>().illustrations;

    Widget? sceneImage, prevSceneImage;
    if (scene != null) {
      sceneImage = SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Image(
          image: AssetImage(scene),
          fit: BoxFit.cover,
        ),
      );
    }
    if (prevScene != null) {
      prevSceneImage = SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Image(
          image: AssetImage(prevScene),
          fit: BoxFit.cover,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (isFadeIn && sceneImage != null) ...[
            if (prevSceneImage != null) prevSceneImage,
            FadeTransition(
              opacity: fadeAnimation,
              child: sceneImage,
            )
          ] else if (isFadeOut && prevSceneImage != null) ...[
            if (sceneImage != null) sceneImage,
            FadeTransition(
              opacity: fadeAnimation,
              child: prevSceneImage,
            )
          ] else if (sceneImage != null)
            sceneImage,
          ...illustrations.values.map(
            (imageInfo) => Positioned(
              top: 150.0 + imageInfo.positionYOffset,
              left: (screenSize.width - kIllustrationWidth) / 2 +
                  imageInfo.positionXOffset,
              child: Container(
                width: kIllustrationWidth,
                height: kIllustrationHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    alignment: Alignment.topCenter,
                    image: AssetImage(imageInfo.imagePath),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
