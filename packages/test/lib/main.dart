import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:samsara/widget/markdown_wiki.dart';

import 'ui/main_menu.dart';
import 'global.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runZonedGuarded(() {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? widget) {
          Widget error =
              const Text('an error occurred while rendering this widget...');
          if (widget is Scaffold || widget is Navigator) {
            error = Scaffold(body: Center(child: error));
          }
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) => error;
          if (widget != null) return widget;
          throw ('widget is null');
        },
        title: 'Heavenly Tribulation Tests',
        initialRoute: '/',
        routes: {
          '/': (context) => const MainMenu(),
          'wiki': (context) => MarkdownWiki(
                resourceManager: AssetManager(),
              ),
        },
      ),
    );
  }, (Object error, StackTrace stack) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'An unexpected error happened!',
      text: '$error\n\n$stack',
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  });
}
