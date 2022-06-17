import 'package:hetu_script/hetu_script.dart';

import '../ui/dialog/game_dialog/game_dialog.dart';
import '../ui/dialog/selection_dialog.dart';
import '../ui/view/duel/duel.dart';
import '../ui/dialog/character_selection_dialog.dart';

final Map<String, Function> externalGameFunctions = {
  r'_showGameDialog': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return GameDialog.show(positionalArgs[0], positionalArgs[1]);
  },
  r'_showSelectionDialog': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return SelectionDialog.show(positionalArgs[0], positionalArgs[1]);
  },
  r'_showCharacterSelectionDialog': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return CharacterSelectionDialog.show(positionalArgs[0], positionalArgs[1]);
  },
  r'_showDuel': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return Duel.show(positionalArgs[0], positionalArgs[1]);
  },
};
