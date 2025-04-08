import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/state/states.dart';
import 'package:samsara/samsara.dart';
import 'package:provider/provider.dart';

import '../common.dart';
import 'mainmenu_buttons.dart';
import '../../widgets/ui_overlay.dart';
import '../../game/data.dart';
import '../../engine.dart';

class MainMenuScene extends Scene {
  MainMenuScene({
    // required super.controller,
    required super.context,
  }) : super(
          id: Scenes.mainmenu,
          bgm: engine.bgm,
          bgmFile: 'chinese-oriental-tune-06-12062.mp3',
          bgmVolume: engine.config.musicVolume,
        );

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) async {
    super.onStart(arguments);

    if (arguments['reset'] == true) {
      // 创建一个空游戏存档并初始化一些数据，这主要是为了在主菜单快速测试和debug相关功能，并不会保存
      // 真正开始游戏后还会再执行一遍，
      await GameData.createGame('debug');
      // GameData.isGameCreated = false;
      engine.hetu.invoke(
        'generateHero',
        namespace: 'Debug',
        namedArgs: {
          'level': 6,
          'rank': 1,
        },
      );
      // engine.hetu.invoke('acquireById',
      //     namespace: 'Player', positionalArgs: ['hunguding']);
      context.read<HeroState>().update();
      context.read<HeroInfoVisibilityState>().setVisible(true);
      context.read<GameTimestampState>().update();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneWidget(scene: this),
        MainMenuButtons(),
        GameUIOverlay(action: DebugButton()),
      ],
    );
  }
}
