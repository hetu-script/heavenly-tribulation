import 'package:samsara/samsara.dart';
import 'package:samsara/game_dialog/game_dialog.dart';

import 'state/game_state.dart';
import 'state/game_config.dart';

const defaultGameSize = Size(1440.0, 810.0);

final engine = SamsaraEngine(
  config: EngineConfig(
    name: 'Heavenly Tribulation',
    developmentMode: true,
    musicVolume: 0.5,
    soundEffectVolume: 0.5,
    showFps: false,
    enableLlm: false,
    llmModelId: 'gemma-4-E4B-it-Q5_K_M',
    mods: {
      'story': {
        'enabled': false,
      },
    },
  ),
);

final dialog = GameDialog();

final gameState = GameState();

final gameConfig = GameConfigState();
