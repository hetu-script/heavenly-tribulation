import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/error.dart';

import 'ui/main_menu.dart';
import 'global.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 对于Flutter没有捕捉到的错误，弹出系统原生对话框
    PlatformDispatcher.instance.onError = (error, stack) {
      alertNativeError(error, stack);
      return true;
    };

    // 对于Flutter捕捉到的错误，弹出Flutter绘制的自定义对话框
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      alertFlutterError(details);
    };

    assert(Platform.isLinux || Platform.isWindows || Platform.isMacOS);
    await windowManager.ensureInitialized();
    windowManager.setTitle(engine.name);
    await windowManager.setMaximizable(false);
    await windowManager.setResizable(false);
    const windowSize = Size(1440.0, 900.0);
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'Heavenly Tribulation Tests',
        // fullScreen: true,
        size: windowSize,
        minimumSize: windowSize,
        maximumSize: windowSize,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
        engine.debug('系统版本：${Platform.operatingSystemVersion}');
      },
    );

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
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
