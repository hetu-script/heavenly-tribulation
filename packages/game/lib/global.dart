import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';

final SamsaraEngine engine = SamsaraEngine(debugMode: kDebugMode);

const kForegroundColor = Colors.white;
final kBackgroundColor = Colors.black.withOpacity(0.75);
final kBarrierColor = Colors.black.withOpacity(0.5);
final kBorderRadius = BorderRadius.circular(5.0);

const iconTheme = IconThemeData(
  color: kForegroundColor,
);

final lightTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'NotoSansMono',
  colorScheme: const ColorScheme.dark(),
  backgroundColor: kBackgroundColor,
  scaffoldBackgroundColor: kBackgroundColor,
  appBarTheme: AppBarTheme(
    color: kBackgroundColor,
    toolbarHeight: 40,
    elevation: 1,
    iconTheme: iconTheme,
    actionsIconTheme: iconTheme,
  ),
  dialogBackgroundColor: kBarrierColor,
  iconTheme: iconTheme,
  cardTheme: CardTheme(
    elevation: 0.5,
    shape: RoundedRectangleBorder(
      borderRadius: kBorderRadius,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      primary: kBackgroundColor,
      onPrimary: kForegroundColor,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: kForegroundColor,
        ),
        borderRadius: BorderRadius.circular(5.0),
      ),
    ),
  ),
);

enum OrientationMode {
  landscape,
  portrait,
}

abstract class GlobalConfig {
  static ThemeData theme = lightTheme;
  static bool isOnDesktop = false;
  static OrientationMode orientationMode = OrientationMode.landscape;
  static Size screenSize = Size.zero;
}
