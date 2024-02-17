import 'dart:io';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:window_manager/window_manager.dart';
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

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    dataTableShowLogs = false;
    // 对于Flutter没有捕捉到的错误，弹出系统原生对话框
    PlatformDispatcher.instance.onError = (error, stack) {
      alertNativeError(error, stack);
      return false;
    };

    // 对于Flutter捕捉到的错误，弹出Flutter绘制的自定义对话框
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      alertFlutterError(details);
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
      // Global.screenSize = window.physicalSize / window.devicePixelRatio;
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      Global.isOnDesktop = true;
      Global.isPortraitMode = false;
      await windowManager.ensureInitialized();
      windowManager.addListener(CustomWindowListener());
      await windowManager.setMaximizable(false);
      await windowManager.setResizable(false);
      windowManager.waitUntilReadyToShow(
          const WindowOptions(
            title: 'Heavenly Tribulation',
            // fullScreen: true,
            maximumSize: Size(1440.0, 900.0),
            minimumSize: Size(1440.0, 900.0),
          ), () async {
        await windowManager.show();
        await windowManager.focus();
        Global.screenSize = await windowManager.getSize();
        engine.info('系统版本：${Platform.operatingSystemVersion}');
        engine.info(
            '窗口逻辑大小：${Global.screenSize.width}x${Global.screenSize.height}');
      });
    }

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Global.appTheme,
        home: Scaffold(
          key: mainKey,
          body: const MainMenu(),
        ),
        // 控件绘制时发生错误，用一个显示错误信息的控件替代
        builder: (context, widget) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            String stack = '';
            if (details.stack != null) {
              stack = trimStackTrace(details.stack!);
            }
            final Object exception = details.exception;
            Widget error = ErrorWidget.withDetails(
                message: '$exception\n$stack',
                error: exception is FlutterError ? exception : null);
            if (widget is Scaffold || widget is Navigator) {
              error = Scaffold(body: Center(child: error));
            }
            return error;
          };
          if (widget != null) return widget;
          throw ('error trying to create error widget!');
        },
      ),
    );
  }, alertNativeError);
}
