import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:heavenly_tribulation/state/states.dart';
import 'package:samsara/samsara.dart';
import 'package:provider/provider.dart';

import '../common.dart';
import 'mainmenu_buttons.dart';
import '../../widgets/ui_overlay.dart';
import '../../data.dart';
import '../../engine.dart';

class MainMenuScene extends Scene {
  MainMenuScene({
    // required super.controller,
    required super.context,
  }) : super(
          id: Scenes.mainmenu,
          bgm: engine.bgm,
          bgmFile: 'chinese-oriental-tune-06-12062.mp3',
          bgmVolume: GameConfig.musicVolume,
        );

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) async {
    super.onStart(arguments);

    if (kDebugMode && arguments['reset'] == true) {
      // 创建一个空游戏存档并初始化一些数据，这主要是为了在主菜单快速测试和debug相关功能，并不会保存
      // 真正开始游戏后还会再执行一遍，
      await GameData.createGame('debug');
      GameData.isGameCreated = false;
      assert(context.mounted);
      if (context.mounted) {
        engine.hetu.invoke('generateHero', namespace: 'Debug', namedArgs: {
          'rank': 2,
          'level': 10,
        });
        engine.hetu.invoke('testCardpack', namespace: 'Debug', namedArgs: {
          'amount': 24,
        });
        engine.hetu.invoke('testEquipment', namespace: 'Debug', namedArgs: {
          'amount': 24,
        });
        context.read<HeroState>().update();
        context.read<GameUIOverlayVisibilityState>().setVisible();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneWidget(scene: this),
        MainMenuButtons(),
        const Positioned(
          left: 0,
          top: 0,
          child: GameUIOverlay(),
        ),
      ],
    );
  }
}
