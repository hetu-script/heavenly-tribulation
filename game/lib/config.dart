import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

const kForegroundColor = Colors.white;
final kBackgroundColor = Colors.black.withOpacity(0.75);
final kBarrierColor = Colors.black.withOpacity(0.5);
final kBorderRadius = BorderRadius.circular(5.0);

const iconTheme = IconThemeData(
  color: kForegroundColor,
);

const captionStyle = TextStyle(
  fontFamily: 'RuiZiYunZiKuLiBianTiGBK',
  fontSize: 18.0,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'RuiZiYunZiKuLiBianTiGBK',
  colorScheme: ColorScheme.dark(
    background: kBackgroundColor,
  ),
  scaffoldBackgroundColor: Colors.transparent,
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
      fontFamily: 'RuiZiYunZiKuLiBianTiGBK',
      color: kForegroundColor,
    ),
  ),
  dividerColor: kForegroundColor,
);

abstract class GameConfig {
  static String gameTitle = 'Heavenly Tribulation';
  static ThemeData appTheme = darkTheme;
  static bool isDebugMode = true;
  static Size screenSize = Size.zero;
  static double musicVolume = 0.5;
  static double soundEffectVolume = 0.5;
  static Map<String, dynamic> modules = {
    'tutorial': {
      'enabled': true,
      'preinclude': true,
    }
  };
}

const kValueTypeInt = 'int';
const kValueTypeFloat = 'float';
const kValueTypePercentage = 'percentage';

final SamsaraEngine engine = SamsaraEngine(
  config: EngineConfig(
    debugMode: GameConfig.isDebugMode,
    isOnDesktop: true,
  ),
);
