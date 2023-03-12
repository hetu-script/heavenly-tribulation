import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../scene/cardgame/card_battle/character.dart';

extension BattleCharacterBinding on BattleCharacter {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'takeDamage':
        return (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            takeDamage(positionalArgs.first);
      default:
        throw HTError.undefined(varName);
    }
  }
}

class BattleCharacterClassBinding extends HTExternalClass {
  BattleCharacterClassBinding() : super(r'BattleCharacter');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as BattleCharacter;
    return i.htFetch(varName);
  }
}
