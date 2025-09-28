import 'package:samsara/samsara.dart';
import 'state/game_dialog.dart';

// TODO: 将读取config挪到GameData中
final SamsaraEngine engine = SamsaraEngine(
  config: EngineConfig(
    name: 'Heavenly Tribulation',
    desktop: true,
    debugMode: true,
    musicVolume: 0.5,
    soundEffectVolume: 0.5,
    cursors: {
      'normal': 'assets/images/cursor/sword.png',
      'click': 'assets/images/cursor/click.png',
      'press': 'assets/images/cursor/press.png',
      'drag': 'assets/images/cursor/drag.png',
    },
    mods: {
      'story': {
        'enabled': true,
        'preinclude': true,
      },
    },
    showFps: true,
  ),
);

final dialog = GameDialog.singleton;
