import 'dart:io';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'app.dart';
import 'engine.dart';
import 'state/states.dart';
import 'game/ui.dart';

class CustomWindowListener extends WindowListener {
  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    // engine.info('窗口大小修改为：${size.width}x${size.height}');
    GameUI.resizeTo(size.toVector2());
  }

  // @override
  // void onWindowFocus() async {
  //   // engine.info('窗口获得焦点');
  //   engine.setCursor(Cursors.normal);
  // }
}

class NoThumbScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

void main() {
  dataTableShowLogs = false;

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 对于Flutter没有捕捉到的错误，弹出系统原生对话框
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      final statck = trimStackTrace(stackTrace);
      engine.error('$error\n$statck');
      alertNativeError(error, statck);
      return false;
    };

    // 对于Flutter捕捉到的错误，弹出Flutter绘制的自定义对话框
    FlutterError.onError = (details) {
      engine.error(details.toString());
      FlutterError.presentError(details);
      alertFlutterError(details);
    };

    assert(Platform.isLinux || Platform.isWindows || Platform.isMacOS);
    await windowManager.ensureInitialized();
    windowManager.addListener(CustomWindowListener());
    await windowManager.setMaximizable(false);
    await windowManager.setResizable(false);
    const windowSize = Size(1440.0, 900.0);
    await windowManager.waitUntilReadyToShow(
        const WindowOptions(
          title: 'Heavenly Tribulation',
          // fullScreen: true,
          size: windowSize,
          maximumSize: windowSize,
          minimumSize: windowSize,
        ), () async {
      await windowManager.show();
      await windowManager.focus();
      engine.debug('系统版本：${Platform.operatingSystemVersion}');
    });

    await engine.registerCursors();
    // engine.setCursor(Cursors.normal);

    runApp(
      MouseRegion(
        //   opaque: false,
        cursor: FlutterCustomMemoryImageCursor(key: 'normal'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => engine),
            ChangeNotifierProvider(create: (_) => dialog),
            ChangeNotifierProvider(create: (_) => GameSavesState()),
            ChangeNotifierProvider(create: (_) => EditorToolState()),
            ChangeNotifierProvider(create: (_) => HeroAndGlobalHistoryState()),
            ChangeNotifierProvider(create: (_) => SelectedPositionState()),
            ChangeNotifierProvider(create: (_) => HeroPositionState()),
            ChangeNotifierProvider(create: (_) => NpcListState()),
            ChangeNotifierProvider(create: (_) => NewQuestState()),
            ChangeNotifierProvider(create: (_) => NewItemsState()),
            ChangeNotifierProvider(create: (_) => NewRankState()),
            ChangeNotifierProvider(create: (_) => HeroInfoVisibilityState()),
            ChangeNotifierProvider(create: (_) => HeroState()),
            ChangeNotifierProvider(create: (_) => EnemyState()),
            ChangeNotifierProvider(create: (_) => MerchantState()),
            ChangeNotifierProvider(create: (_) => ItemSelectState()),
            ChangeNotifierProvider(create: (_) => ViewPanelState()),
            ChangeNotifierProvider(create: (_) => ViewPanelPositionState()),
            ChangeNotifierProvider(create: (_) => HoverContentState()),
            ChangeNotifierProvider(
                create: (_) => HoverContentDeterminedRectState()),
            ChangeNotifierProvider(create: (_) => GameTimestampState()),
          ],
          child: fluent.FluentTheme(
            data: GameUI.fluentTheme,
            child: MaterialApp(
              scrollBehavior:
                  NoThumbScrollBehavior().copyWith(scrollbars: false),
              debugShowCheckedModeBanner: false,
              theme: GameUI.darkMaterialTheme,
              home: GameApp(key: mainKey),
              // onNavigationNotification: (notification) {
              //   engine.setCursor(Cursors.normal);
              //   return notification.canHandlePop;
              // },
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
          ),
        ),
      ),
    );
  }, alertNativeError);
}
