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
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    color: Colors.transparent,
    toolbarHeight: 36,
    iconTheme: iconTheme,
    actionsIconTheme: iconTheme,
    titleTextStyle: TextStyle(
      fontFamily: 'NotoSansMono',
      fontSize: 18.0,
    ),
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
  sliderTheme: const SliderThemeData(
    activeTrackColor: kForegroundColor,
    activeTickMarkColor: kForegroundColor,
    thumbColor: kForegroundColor,
    valueIndicatorTextStyle: TextStyle(
      fontFamily: 'NotoSansMono',
      color: kForegroundColor,
    ),
  ),
  dividerColor: kForegroundColor,
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
