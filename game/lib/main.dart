import 'dart:io';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:samsara/error.dart';

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
    engine
        .info('窗口大小修改为：${Global.screenSize.width}x${Global.screenSize.height}');
    Global.screenSize = await windowManager.getSize();
  }
}

void main() async {
  dataTableShowLogs = false;
  WidgetsFlutterBinding.ensureInitialized();

  // 对于Flutter没有捕捉到的错误，弹出系统原生对话框
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'An unexpected error happened!',
      text: '$error\n\n$stack',
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
    return true;
  };

  // 对于Flutter捕捉到的错误，弹出Flutter绘制的自定义对话框
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    onError(details);
  };

  // 控件绘制时发生错误，用一个显示错误信息的控件替代
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final Object exception = details.exception;
    return ErrorWidget.withDetails(
        message: '$exception\n\n${details.stack}',
        error: exception is FlutterError ? exception : null);
  };

  if (Platform.isAndroid || Platform.isIOS) {
    Global.isOnDesktop = false;
    Global.isPortraitMode = true;
    await Flame.device.setPortraitDownOnly();
    await Flame.device.fullScreen();
    Global.screenSize = window.physicalSize / window.devicePixelRatio;
  } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    Global.isOnDesktop = true;
    Global.isPortraitMode = false;
    await windowManager.ensureInitialized();
    windowManager.addListener(CustomWindowListener());
    WindowOptions windowOptions = const WindowOptions(
      // fullScreen: true,
      minimumSize: Size(1280.0, 720.0),
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

  runZonedGuarded(() {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Global.appTheme,
        home: Scaffold(
          key: mainKey,
          body: const MainMenu(),
        ),
        // routes: {
        //   'worldmap': (context) => MainGameOverlay(key: UniqueKey()),
        //   'location': (context) => const LocationView(),
        //   'information': (context) => const InformationPanel(),
        //   'character': (context) => const CharacterView(),
        //   // 'editor': (context) => const GameEditor(),
        // },
      ),
    );
  }, (Object error, StackTrace stack) {
    engine.error(error.toString());
    onError(FlutterErrorDetails(
      exception: error,
      stack: stack,
    ));
  });
}
