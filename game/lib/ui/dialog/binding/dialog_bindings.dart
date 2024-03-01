import 'package:hetu_script/value/function/function.dart';

import '../game_dialog.dart';
import '../selection_dialog.dart';
// import '../ui/view/duel/duel.dart';
import '../character_visit_dialog.dart';
import '../character_select_dialog.dart';
import '../../view/merchant/merchant.dart';
import '../../view/quest/quests.dart';
import '../../../pages/map/maze/maze.dart';
import '../progress_indicator.dart';
import '../integer_input.dart';
import '../skill_select_dialog.dart';

final Map<String, Function> dialogFunctions = {
  r'showGameDialog': ({positionalArgs, namedArgs}) {
    return GameDialog.show(
      context: positionalArgs[0],
      dialogData: positionalArgs[1],
      returnValue: positionalArgs[2],
    );
  },
  r'showSelection': ({positionalArgs, namedArgs}) {
    return SelectionDialog.show(
      context: positionalArgs[0],
      selections: positionalArgs[1],
    );
  },
  r'showCharacterSelection': ({positionalArgs, namedArgs}) {
    return CharacterSelectDialog.show(
      context: positionalArgs[0],
      title: positionalArgs[1],
      characterIds: positionalArgs[2],
      showCloseButton: positionalArgs[3],
    );
  },
  r'showVisitCharacterSelection': ({positionalArgs, namedArgs}) {
    return CharacterVisitDialog.show(
      context: positionalArgs[0],
      characterIds: positionalArgs[1],
    );
  },
  r'showSkillSelection': ({positionalArgs, namedArgs}) {
    return SkillSelectDialog.show(
      context: positionalArgs[0],
      title: positionalArgs[1],
      skillsData: positionalArgs[2],
      showCloseButton: positionalArgs[3],
    );
  },
  // r'showDuel': (HTEntity object,
  //     {List<dynamic> positionalArgs = const [],
  //     Map<String, dynamic> namedArgs = const {},
  //     List<HTType> typeArgs = const []}) {
  //   return Duel.show(
  //     context: positionalArgs[0],
  //     char1: positionalArgs[1],
  //     char2: positionalArgs[2],
  //     type: positionalArgs[3],
  //     data: positionalArgs[4],
  //   );
  // },
  r'showMerchant': ({positionalArgs, namedArgs}) {
    return MerchantView.show(
      context: positionalArgs[0],
      merchantData: positionalArgs[1],
      priceFactor: positionalArgs[2],
      allowSell: positionalArgs[3],
      sellableCategory: positionalArgs[4],
      sellableKind: positionalArgs[5],
    );
  },
  r'showQuests': ({positionalArgs, namedArgs}) {
    return QuestsView.show(
      context: positionalArgs[0],
      siteData: positionalArgs[1],
    );
  },
  r'showMaze': ({positionalArgs, namedArgs}) {
    return MazeOverlay.show(
      context: positionalArgs[0],
      mazeData: positionalArgs[1],
    );
  },
  r'showProgress': ({positionalArgs, namedArgs}) {
    bool Function()? func;
    if (positionalArgs[2] is HTFunction) {
      func = () => (positionalArgs[2] as HTFunction).call();
    }
    return ProgressIndicator.show(
      context: positionalArgs[0],
      title: positionalArgs[1],
      checkProgress: func,
    );
  },
  r'showIntInput': ({positionalArgs, namedArgs}) {
    return IntegerInputDialog.show(
      context: positionalArgs[0],
      title: positionalArgs[1],
      min: positionalArgs[2],
      max: positionalArgs[3],
    );
  },
};
