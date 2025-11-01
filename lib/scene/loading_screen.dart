import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/engine.dart';

import '../global.dart';
import '../ui.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: 一些随机展示的游戏CG;
    final tip = context.watch<SamsaraEngine>().loadingTip;
    final message = context.watch<SamsaraEngine>().loadingMessage;

    return Material(
      type: MaterialType.canvas,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    engine.isInitted ? engine.locale('loading') : 'loading...',
                    style: TextStyles.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: tip != null
                      ? Text(
                          tip,
                          style: TextStyles.titleLarge,
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: message != null
                      ? Text(
                          message,
                          style: TextStyles.titleLarge,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
