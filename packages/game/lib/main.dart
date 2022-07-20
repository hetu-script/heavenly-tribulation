import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:window_manager/window_manager.dart';

// import 'ui/view/location/location.dart';
import 'ui/main_menu.dart';
// import 'ui/editor/editor.dart';
// import 'ui/view/character/character.dart';
// import 'ui/view/information/information.dart';
import 'global.dart';
// import 'ui/overlay/main_game.dart';

class CustomWindowListener extends WindowListener {
  @override
  void onWindowResize() async {
    engine.info(
        '窗口大小已经修改为：${Global.screenSize.width}x${Global.screenSize.height}');
    Global.screenSize = await windowManager.getSize();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    Global.isOnDesktop = false;
    Global.orientationMode = OrientationMode.portrait;
    await Flame.device.setPortraitDownOnly();
    await Flame.device.fullScreen();
    Global.screenSize = window.physicalSize / window.devicePixelRatio;
  } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    Global.isOnDesktop = true;
    Global.orientationMode = OrientationMode.landscape;
    await windowManager.ensureInitialized();
    windowManager.addListener(CustomWindowListener());
    WindowOptions windowOptions = const WindowOptions(
      // fullScreen: true,
      size: Size(800.0, 600.0),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      Global.screenSize = await windowManager.getSize();
      engine.info('系统版本：${Platform.operatingSystemVersion}');
      engine.info(
          '窗口逻辑大小：${Global.screenSize.width}x${Global.screenSize.height}');
    });
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    // In release builds, show a yellow-on-blue message instead:
    return Container(
      color: Colors.red,
      alignment: Alignment.center,
      child: Text(
        'Error!\n${details.exception}',
        style: const TextStyle(color: Colors.yellow),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      ),
    );
  };

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Global.appTheme,
      builder: (BuildContext context, Widget? widget) {
        Widget error = const Text('...rendering error...');
        if (widget is Scaffold || widget is Navigator) {
          error = Scaffold(body: Center(child: error));
        }
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) => error;
        if (widget != null) return widget;
        throw ('widget is null');
      },
      home: const MainMenu(),
      // routes: {
      //   'worldmap': (context) => MainGameOverlay(key: UniqueKey()),
      //   'location': (context) => const LocationView(),
      //   'information': (context) => const InformationPanel(),
      //   'character': (context) => const CharacterView(),
      //   // 'editor': (context) => const GameEditor(),
      // },
    ),
  );
}
