import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

extension PercentageString on num {
  String toPercentageString([int fractionDigits = 0]) {
    return '${(this * 100).toStringAsFixed(fractionDigits).toString()}%';
  }
}

extension DoubleFixed on double {
  double toDoubleAsFixed([int n = 2]) {
    return double.parse(toStringAsFixed(n));
  }
}

const kForegroundColor = Colors.white;
final kBackgroundColor = Colors.black.withOpacity(0.75);
final kBarrierColor = Colors.black.withOpacity(0.5);
final kBorderRadius = BorderRadius.circular(5.0);

const iconTheme = IconThemeData(
  color: kForegroundColor,
);

const captionStyle = TextStyle(
  fontFamily: 'NotoSansMono',
  fontSize: 18.0,
);

final lightTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'NotoSansMono',
  colorScheme: ColorScheme.dark(
    background: kBackgroundColor,
  ),
  scaffoldBackgroundColor: kBackgroundColor,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    color: Colors.transparent,
    toolbarHeight: 36,
    iconTheme: iconTheme,
    actionsIconTheme: iconTheme,
    titleTextStyle: captionStyle,
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
      backgroundColor: kBackgroundColor,
      foregroundColor: kForegroundColor,
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

abstract class Global {
  static ThemeData appTheme = lightTheme;
  static bool isDebugMode = true;
  static bool isOnDesktop = false;
  static bool isPortraitMode = false;
  static Size screenSize = Size.zero;
}

const kValueTypeInt = 'int';
const kValueTypeFloat = 'float';
const kValueTypePercentage = 'percentage';

final SamsaraEngine engine = SamsaraEngine(
  config: EngineConfig(
    name: 'Heavenly Tribulation',
    debugMode: Global.isDebugMode,
  ),
);

final heroSrcSize = Vector2(32.0, 48.0);
