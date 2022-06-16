import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/view/location/location.dart';
import 'ui/main_menu.dart';
import 'ui/editor/editor.dart';
import 'ui/view/character/character.dart';
import 'ui/view/information/information.dart';
import 'global.dart';

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
    // WindowOptions windowOptions = const WindowOptions(
    //   fullScreen: true,
    // );
    // windowManager.waitUntilReadyToShow(windowOptions, () async {
    //   await windowManager.show();
    //   await windowManager.focus();
    // });
    GlobalConfig.screenSize = await windowManager.getSize();
  }

  engine.info('系统版本：${Platform.operatingSystemVersion}');
  engine.info(
      '逻辑分辨率：${GlobalConfig.screenSize.width}x${GlobalConfig.screenSize.height}');

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: GlobalConfig.theme,
      home: MainMenu(key: UniqueKey()),
      routes: {
        'location': (context) => LocationView(),
        'information': (context) => const InformationPanel(),
        'character': (context) => const CharacterView(),
        'editor': (context) => const GameEditor(),
      },
    ),
  );
}
