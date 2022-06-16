import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';

final SamsaraEngine engine = SamsaraEngine(debugMode: kDebugMode);

const iconTheme = IconThemeData(
  color: Colors.white,
);

final kBackgroundColor = Colors.black.withOpacity(0.75);
final kBarrierColor = Colors.black.withOpacity(0.25);
final kBorderRadius = BorderRadius.circular(5.0);

final lightTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'UbuntuMono',
  colorScheme: const ColorScheme.dark(),
  backgroundColor: kBackgroundColor,
  scaffoldBackgroundColor: kBackgroundColor,
  appBarTheme: AppBarTheme(
    color: kBackgroundColor,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
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
  textTheme: const TextTheme(
    button: TextStyle(fontSize: 18),
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
