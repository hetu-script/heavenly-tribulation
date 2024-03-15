import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../../config.dart';
import '../../state/game_dialog_state.dart';

class GameDialogController extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
  }) {
    return showDialog<dynamic>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const GameDialogController();
      },
    );
  }

  const GameDialogController({super.key});

  @override
  State<GameDialogController> createState() => _GameDialogControllerState();
}

class _GameDialogControllerState extends State<GameDialogController> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // TODO: 场景进出的转场效果 + 角色图片的位移效果
    final scene = context.watch<GameDialogState>().scenes.lastOrNull;
    final illustrations = context.watch<GameDialogState>().illustrations;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (scene != null)
            Positioned.fill(
              child: Image(
                  image: AssetImage('assets/images/cg/$scene'),
                  fit: BoxFit.cover),
            ),
          ...illustrations.keys.map(
            (image) => Positioned(
              top: 150.0,
              left: screenWidth / 2 + illustrations[image]!,
              child: Container(
                width: 600.0,
                height: 900.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    alignment: Alignment.topCenter,
                    image: AssetImage('assets/images/avatar/$image'),
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
