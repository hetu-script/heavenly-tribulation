import 'package:hetu_script/value/function/function.dart';

import '../game_dialog/game_dialog.dart';
import '../game_dialog/selection_dialog.dart';
// import '../ui/view/duel/duel.dart';
import '../character_visit_dialog.dart';
import '../character_select_dialog.dart';
import '../../view/merchant/merchant.dart';
import '../../view/quest/quests.dart';
// import '../../scene/map/maze/maze_overlay.dart';
import '../progress_indicator.dart';
import '../input_integer.dart';

final Map<String, Function> dialogFunctions = {
  r'_say': ({positionalArgs, namedArgs}) {
    return GameDialog.show(
      context: positionalArgs[0],
      dialogData: positionalArgs[1],
      returnValue: positionalArgs[2],
    );
  },
  r'_select': ({positionalArgs, namedArgs}) {
    return SelectionDialog.show(
      context: positionalArgs[0],
      selectionsData: positionalArgs[1],
    );
  },
  r'_characterSelect': ({positionalArgs, namedArgs}) {
    return CharacterSelectDialog.show(
      context: positionalArgs[0],
      title: positionalArgs[1],
      characterIds: positionalArgs[2],
      showCloseButton: positionalArgs[3],
    );
  },
  r'_visitSelect': ({positionalArgs, namedArgs}) {
    return CharacterVisitDialog.show(
      context: positionalArgs[0],
      characterIds: positionalArgs[1],
      hideHero: namedArgs['hideHero'],
    );
  },
  r'_merchant': ({positionalArgs, namedArgs}) {
    return MerchantView.show(
      context: positionalArgs[0],
      merchantData: positionalArgs[1],
      priceFactor: positionalArgs[2],
      allowSell: positionalArgs[3],
      sellableCategory: positionalArgs[4],
      sellableKind: positionalArgs[5],
    );
  },
  r'_quests': ({positionalArgs, namedArgs}) {
    return QuestsView.show(
      context: positionalArgs[0],
      siteData: positionalArgs[1],
    );
  },
  r'_progress': ({positionalArgs, namedArgs}) {
    bool? Function()? func;
    if (positionalArgs[2] is HTFunction) {
      func = () => (positionalArgs[2] as HTFunction).call();
    }
    return ProgressIndicator.show(
      context: positionalArgs[0],
      title: positionalArgs[1],
      checkProgress: func,
    );
  },
  r'_inputInteger': ({positionalArgs, namedArgs}) {
    return InputIntegerDialog.show(
      context: positionalArgs[0],
      title: positionalArgs[1],
      min: positionalArgs[2],
      max: positionalArgs[3],
    );
  },
};
