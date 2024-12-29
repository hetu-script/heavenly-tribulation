import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';
import 'package:flutter/material.dart' show Colors;

import '../components/character.dart';

class BattleCharacterClassBinding extends HTExternalClass {
  BattleCharacterClassBinding() : super(r'BattleCharacter');

  @override
  dynamic instanceMemberGet(dynamic instance, String varName,
      {bool ignoreUndefined = false}) {
    var character = instance as BattleCharacter;
    switch (varName) {
      case 'priority':
        return character.priority;
      case 'addHintText':
        return ({positionalArgs, namedArgs}) {
          final color = switch (namedArgs['color']) {
            _ => Colors.white,
          };
          character.addHintText(positionalArgs.first, color: color);
        };
      case 'restoreLife':
        return ({positionalArgs, namedArgs}) =>
            character.restoreLife(positionalArgs.first);
      case 'consumeMana':
        return ({positionalArgs, namedArgs}) =>
            character.consumeMana(positionalArgs.first);
      case 'restoreMana':
        return ({positionalArgs, namedArgs}) =>
            character.restoreMana(positionalArgs.first);
      // case 'spell':
      //   return ({positionalArgs, namedArgs}) =>
      //       character.setSpellState(positionalArgs.first);
      case 'defend':
        return ({positionalArgs, namedArgs}) =>
            character.setDefendState(positionalArgs.first);
      case 'attack':
        return ({positionalArgs, namedArgs}) =>
            character.setAttackState(positionalArgs.first);
      case 'takeDamage':
        return ({positionalArgs, namedArgs}) {
          dynamic v = positionalArgs[1];
          if (v is int) {
            return character.takeDamage(positionalArgs[0], damage: v);
          } else if (v is List) {
            return character.takeDamage(positionalArgs[0],
                multipleDamages: List<int>.from(v));
          }
        };
      case 'setState':
        return ({positionalArgs, namedArgs}) => character.setState(
            positionalArgs.first,
            resetOnComplete: namedArgs['reset']);
      case 'hasStatusEffect':
        return ({positionalArgs, namedArgs}) =>
            character.hasStatusEffect(positionalArgs.first);
      case 'removeStatusEffect':
        return ({positionalArgs, namedArgs}) => character.removeStatusEffect(
              positionalArgs[0],
              amount: namedArgs['amount'],
              percentage: namedArgs['percentage'],
            );
      case 'addStatusEffect':
        return ({positionalArgs, namedArgs}) => character.addStatusEffect(
            positionalArgs[0],
            amount: namedArgs['amount'],
            playSound: namedArgs['playSound']);
      case 'setTurnFlag':
        return ({positionalArgs, namedArgs}) =>
            character.setTurnFlag(positionalArgs[0]);
      case 'hasTurnFlag':
        return ({positionalArgs, namedArgs}) =>
            character.hasTurnFlag(positionalArgs[0]);
      case 'removeTurnFlag':
        return ({positionalArgs, namedArgs}) =>
            character.removeTurnFlag(positionalArgs[0]);
      case 'setGameFlag':
        return ({positionalArgs, namedArgs}) =>
            character.setGameFlag(positionalArgs[0]);
      case 'hasGameFlag':
        return ({positionalArgs, namedArgs}) =>
            character.hasGameFlag(positionalArgs[0]);
      case 'removeGameFlag':
        return ({positionalArgs, namedArgs}) =>
            character.removeGameFlag(positionalArgs[0]);

      default:
        if (!ignoreUndefined) throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberSet(dynamic instance, String varName, dynamic value,
      {bool ignoreUndefined = false}) {
    var character = instance as BattleCharacter;
    switch (varName) {
      case 'priority':
        character.priority = value;
      default:
        if (!ignoreUndefined) throw HTError.undefined(varName);
    }
  }
}
