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

    // 控件绘制时发生错误，用一个显示错误信息的控件替代
    ErrorWidget.builder = (FlutterErrorDetails details) {
      final Object exception = details.exception;
      return ErrorWidget.withDetails(
          message: '$exception\n\n${details.stack}',
          error: exception is FlutterError ? exception : null);
    };

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.ensureInitialized();
      windowManager.setTitle(engine.name);
      windowManager.waitUntilReadyToShow(
        const WindowOptions(
          // fullScreen: true,
          minimumSize: Size(1280.0, 720.0),
        ),
        () async {
          await windowManager.show();
          await windowManager.focus();
          final screenSize = await windowManager.getSize();
          engine.info('系统版本：${Platform.operatingSystemVersion}');
          engine.info('窗口逻辑大小：${screenSize.width}x${screenSize.height}');
        },
      );
    }

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Heavenly Tribulation Tests',
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
          throw ('widget is null');
        },
      ),
    );
  }, alertNativeError);
}
