import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';

// TODO: 将读取config挪到GameData中
final SamsaraEngine engine = SamsaraEngine(
  config: EngineConfig(
    name: 'Heavenly Tribulation',
    desktop: true,
    debugMode: kDebugMode,
    musicVolume: 0.5,
    soundEffectVolume: 0.5,
    // cursors: {
    //   'default': 'assets/images/sword.png',
    // }
    mods: {
      'story': {
        'enabled': true,
        'preinclude': true,
      },
    },
    showFps: kDebugMode,
  ),
);
