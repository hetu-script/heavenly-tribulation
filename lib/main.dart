import 'dart:io';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
// import 'package:flame/flame.dart';
import 'package:window_manager/window_manager.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';

// import 'ui/view/location/location.dart';
import 'app.dart';
// import 'ui/editor/editor.dart';
// import 'ui/view/character/character.dart';
// import 'ui/view/information/information.dart';
import 'engine.dart';
// import 'ui/overlay/main_game.dart';
import 'state/states.dart';
import 'game/ui.dart';

// class CustomWindowListener extends WindowListener {
//   @override
//   void onWindowResize() async {
//     engine.info(
//         '窗口大小修改为：${GameConfig.screenSize.width}x${GameConfig.screenSize.height}');
//     GameConfig.screenSize = await windowManager.getSize();
//   }
// }

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
    // windowManager.addListener(CustomWindowListener());
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

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => engine),
          ChangeNotifierProvider(create: (_) => GameSavesState()),
          ChangeNotifierProvider(create: (_) => EditorToolState()),
          ChangeNotifierProvider(create: (_) => HeroAndGlobalHistoryState()),
          ChangeNotifierProvider(create: (_) => SelectedTileState()),
          ChangeNotifierProvider(create: (_) => HeroTileState()),
          ChangeNotifierProvider(create: (_) => GameDialogState()),
          ChangeNotifierProvider(create: (_) => NpcListState()),
          ChangeNotifierProvider(create: (_) => NewQuestState()),
          ChangeNotifierProvider(create: (_) => NewItemsState()),
          ChangeNotifierProvider(create: (_) => NewRankState()),
          ChangeNotifierProvider(create: (_) => HeroInfoVisibilityState()),
          ChangeNotifierProvider(create: (_) => HeroState()),
          ChangeNotifierProvider(create: (_) => EnemyState()),
          ChangeNotifierProvider(create: (_) => MerchantState()),
          ChangeNotifierProvider(create: (_) => ViewPanelState()),
          ChangeNotifierProvider(create: (_) => ViewPanelPositionState()),
          ChangeNotifierProvider(create: (_) => HoverInfoContentState()),
          ChangeNotifierProvider(create: (_) => HoverInfoDeterminedRectState()),
          ChangeNotifierProvider(create: (_) => GameTimestampState()),
        ],
        child: MaterialApp(
          scrollBehavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
          debugShowCheckedModeBanner: false,
          theme: GameUI.darkTheme,
          home: GameApp(key: mainKey),
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
    );
  }, alertNativeError);
}
