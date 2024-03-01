import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../scene/character.dart';

class BattleCharacterClassBinding extends HTExternalClass {
  BattleCharacterClassBinding() : super(r'BattleCharacter');

  @override
  dynamic instanceMemberGet(dynamic instance, String varName) {
    var character = instance as BattleCharacter;
    switch (varName) {
      case 'priority':
        return character.priority;
      // case 'attack':
      //   return character.attack;
      case 'restoreLife':
        return ({positionalArgs, namedArgs}) =>
            character.restoreLife(positionalArgs.first);
      case 'restoreMana':
        return ({positionalArgs, namedArgs}) =>
            character.restoreMana(positionalArgs.first);
      case 'defend':
        return ({positionalArgs, namedArgs}) =>
            character.setDefendState(state: positionalArgs.first);
      case 'attack':
        return ({positionalArgs, namedArgs}) =>
            character.setAttackState(state: positionalArgs.first);
      case 'takeDamage':
        return ({positionalArgs, namedArgs}) {
          assert(positionalArgs.length == 2);
          assert(positionalArgs[1] != null);
          character.takeDamage(positionalArgs[0], positionalArgs[1]);
        };
      case 'setState':
        return ({positionalArgs, namedArgs}) => character.setState(
            positionalArgs.first,
            resetStateWhenComplete: namedArgs['reset']);
      case 'removeStatusEffect':
        return ({positionalArgs, namedArgs}) => character
            .removeStatusEffect(positionalArgs[0], count: positionalArgs[1]);
      case 'addStatusEffect':
        return ({positionalArgs, namedArgs}) => character
            .addStatusEffect(positionalArgs[0], count: positionalArgs[1]);
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberSet(dynamic instance, String varName, dynamic value) {
    var character = instance as BattleCharacter;
    switch (varName) {
      case 'priority':
        character.priority = value;
      default:
        throw HTError.undefined(varName);
    }
  }
}
