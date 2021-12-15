import 'package:hetu_script/hetu_script.dart';

import '../ui/dialog/game_dialog/game_dialog.dart';
import '../ui/dialog/selection_dialog.dart';
import '../ui/dialog/duel/duel.dart';

final Map<String, Function> externalGameFunctions = {
  //external fun _showGameDialog(context, data: Map)
  r'_showGameDialog': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return GameDialog.show(positionalArgs[0], positionalArgs[1]);
  },
  //external fun _showDuel(context, data: Map)
  r'_showSelectionDialog': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return SelectionDialog.show(positionalArgs[0], positionalArgs[1]);
  },
  //external fun _showBattleDialog(context, data: Map)
  r'_showDuel': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return Duel.show(positionalArgs[0], positionalArgs[1]);
  },
};
