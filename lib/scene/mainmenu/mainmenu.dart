import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:provider/provider.dart';

import '../common.dart';
import 'mainmenu_buttons.dart';
import '../../widgets/ui_overlay.dart';
import '../../game/data.dart';
import '../../engine.dart';
import '../../state/states.dart';

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
  Future<void> onLoad() async {
    super.onLoad();
  }

  @override
  void onStart([dynamic arguments = const {}]) async {
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
          // 'level': 10,
          // 'rank': 1,
        },
      );
    } else {
      engine.hetu.invoke('rejuvenate', namespace: 'Player');
    }
    context.read<HeroState>().update();
    context.read<HeroInfoVisibilityState>().setVisible(true);
    context.read<GameTimestampState>().update();
    context.read<HeroAndGlobalHistoryState>().update();
    context.read<NpcListState>().update();

    context.read<HeroPositionState>().updateTerrain(
          currentZoneData: null,
          currentNationData: null,
          currentTerrainData: null,
        );
    context.read<HeroPositionState>().updateLocation(null);
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
        MainMenuButtons(),
        GameUIOverlay(action: DebugButton()),
      ],
    );
  }
}
