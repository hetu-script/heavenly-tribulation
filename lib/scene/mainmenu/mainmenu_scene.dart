import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

import '../common.dart';
import 'mainmenu_widgets.dart';
import '../../widgets/ui_overlay.dart';
import '../../data/game.dart';
import '../../global.dart';

class MainMenuScene extends Scene {
  MainMenuScene()
      : super(
          id: Scenes.mainmenu,
          bgm: engine.bgm,
          bgmFile: 'chinese-oriental-tune-06-12062.mp3',
          bgmVolume: engine.config.musicVolume,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  @override
  void onStart([dynamic arguments = const {}]) async {
    super.onStart(arguments);

    if (arguments['reset'] == true || GameData.game['saveName'] != 'debug') {
      // 创建一个空游戏存档并初始化一些数据，这主要是为了在主菜单快速测试和debug相关功能，并不会保存
      // 真正开始游戏后还会再执行一遍，
      await GameData.createGame(
        'debug',
        seed: DateTime.now().millisecondsSinceEpoch,
      );
      // GameData.isGameCreated = false;
      await engine.hetu.invoke(
        'generateHero',
        namespace: 'debug',
        namedArgs: {
          // 'level': 10,
          // 'rank': 1,
        },
      );
      arguments['reset'] = false;
      engine.setSceneArguments(id, arguments);
    } else {
      engine.hetu.invoke('rejuvenate', namespace: 'Player');
    }
    gameState.reset();
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Stack(
      children: [
        SceneWidget(
          scene: this,
          loadingBuilder: loadingBuilder,
          overlayBuilderMap: overlayBuilderMap,
          initialActiveOverlays: initialActiveOverlays,
        ),
        MainMenuWidgets(),
        GameUIOverlay(
          showJournal: false,
          actions: [
            DebugButton(),
          ],
        ),
      ],
    );
  }
}
