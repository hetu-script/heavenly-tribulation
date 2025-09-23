import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';
import 'package:samsara/extensions.dart';

import 'character.dart';

class BattleCharacterClassBinding extends HTExternalClass {
  BattleCharacterClassBinding() : super(r'BattleCharacter');

  @override
  dynamic instanceMemberGet(dynamic instance, String varName,
      {bool ignoreUndefined = false}) {
    var character = instance as BattleCharacter;
    switch (varName) {
      case 'data':
        return character.data;
      case 'turnFlags':
        return character.turnFlags;
      case 'life':
        return character.life;
      case 'lifeMax':
        return character.lifeMax;
      case 'setLifeMax':
        return ({object, positionalArgs, namedArgs}) {
          character.setLifeMax(positionalArgs.first);
        };
      case 'addHintText':
        return ({object, positionalArgs, namedArgs}) {
          final color = HexColor.fromString(namedArgs['color'] ?? '#FFFFFFFF');
          character.addHintText(positionalArgs.first, color: color);
        };
      case 'changeLife':
        return ({object, positionalArgs, namedArgs}) => character.changeLife(
              positionalArgs[0],
              playSound: namedArgs['playSound'] ?? false,
              isHeal: namedArgs['isHeal'] ?? false,
            );
      case 'takeDamage':
        return ({object, positionalArgs, namedArgs}) {
          return character.takeDamage(positionalArgs.first);
        };
      case 'setState':
        return ({object, positionalArgs, namedArgs}) => character.setState(
              positionalArgs.first,
              isOverlay: namedArgs['isOverlay'],
            );
      case 'setCompositeState':
        return ({object, positionalArgs, namedArgs}) {
          var startup = namedArgs['startup'];
          if (startup != null && startup is! List) {
            startup = [startup];
          }
          var recovery = namedArgs['recovery'];
          if (recovery != null && recovery is! List) {
            recovery = [recovery];
          }
          var actions = namedArgs['actions'];
          if (actions != null && actions is! List) {
            actions = [actions];
          }
          var overlays = namedArgs['overlays'];
          if (overlays != null && overlays is! List) {
            overlays = [overlays];
          }
          return character.setCompositeState(
            startup: startup,
            recovery: recovery,
            actions: actions,
            overlays: overlays,
            complete: namedArgs['complete'],
            sound: namedArgs['sound'],
          );
        };
      case 'hasStatusEffect':
        return ({object, positionalArgs, namedArgs}) =>
            character.hasStatusEffect(positionalArgs.first);
      case 'removeStatusEffect':
        return ({object, positionalArgs, namedArgs}) =>
            character.removeStatusEffect(
              positionalArgs[0],
              amount: namedArgs['amount'],
              percentage: namedArgs['percentage'],
              exhaust: namedArgs['exhaust'],
            );
      case 'addStatusEffect':
        return ({object, positionalArgs, namedArgs}) => character
            .addStatusEffect(positionalArgs[0], amount: namedArgs['amount']);

      default:
        if (!ignoreUndefined) throw HTError.undefined(varName);
    }
  }
}
