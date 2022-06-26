import 'package:hetu_script/hetu_script.dart';

import '../ui/dialog/game_dialog.dart';
import '../ui/dialog/selection_dialog.dart';
import '../ui/view/duel/duel.dart';
import '../ui/dialog/character_visit_dialog.dart';
import '../ui/dialog/character_select_dialog.dart';

final Map<String, Function> externalGameFunctions = {
  r'_showGameDialog': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return GameDialog.show(
      positionalArgs[0],
      positionalArgs[1],
      positionalArgs[2],
    );
  },
  r'_showSelection': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return SelectionDialog.show(
      positionalArgs[0],
      positionalArgs[1],
    );
  },
  r'_showCharacterSelection': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return CharacterSelectDialog.show(
      context: positionalArgs[0],
      title: positionalArgs[1],
      characterIds: positionalArgs[2],
      showCloseButton: positionalArgs[3],
    );
  },
  r'_showVisitCharacterSelection': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return CharacterVisitDialog.show(
      context: positionalArgs[0],
      characterIds: positionalArgs[1],
    );
  },
  r'_showDuel': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return Duel.show(
      positionalArgs[0],
      positionalArgs[1],
      positionalArgs[2],
      positionalArgs[3],
    );
  },
};
