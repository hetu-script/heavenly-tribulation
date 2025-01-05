import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'ui.dart';

abstract class GameConfig {
  static String gameTitle = 'Heavenly Tribulation';
  static ThemeData appTheme = GameUI.darkTheme;
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

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

final SamsaraEngine engine = SamsaraEngine(
  config: EngineConfig(
    name: GameConfig.gameTitle,
    isOnDesktop: true,
    debugMode: GameConfig.isDebugMode,
    musicVolume: GameConfig.musicVolume,
    soundEffectVolume: GameConfig.soundEffectVolume,
  ),
);
