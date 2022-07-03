import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/view/location/location.dart';
import 'ui/main_menu.dart';
// import 'ui/editor/editor.dart';
import 'ui/view/character/character.dart';
import 'ui/view/information/information.dart';
import 'global.dart';
import 'ui/overlay/main_game.dart';

class CustomWindowListener extends WindowListener {
  @override
  void onWindowResize() async {
    engine.info(
        '窗口大小已经修改为：${GlobalConfig.screenSize.width}x${GlobalConfig.screenSize.height}');
    GlobalConfig.screenSize = await windowManager.getSize();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    GlobalConfig.isOnDesktop = false;
    GlobalConfig.orientationMode = OrientationMode.portrait;
    await Flame.device.setPortraitDownOnly();
    await Flame.device.fullScreen();
    GlobalConfig.screenSize = window.physicalSize / window.devicePixelRatio;
  } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    GlobalConfig.isOnDesktop = true;
    GlobalConfig.orientationMode = OrientationMode.landscape;
    await windowManager.ensureInitialized();
    windowManager.addListener(CustomWindowListener());
    WindowOptions windowOptions = const WindowOptions(
      // fullScreen: true,
      size: Size(800.0, 600.0),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      GlobalConfig.screenSize = await windowManager.getSize();
      engine.info('系统版本：${Platform.operatingSystemVersion}');
      engine.info(
          '窗口逻辑大小：${GlobalConfig.screenSize.width}x${GlobalConfig.screenSize.height}');
    });
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: GlobalConfig.theme,
      home: const MainMenu(),
      routes: {
        'worldmap': (context) => MainGameOverlay(key: UniqueKey()),
        'location': (context) => const LocationView(),
        'information': (context) => const InformationPanel(),
        'character': (context) => const CharacterView(),
        // 'editor': (context) => const GameEditor(),
      },
    ),
  );
}
