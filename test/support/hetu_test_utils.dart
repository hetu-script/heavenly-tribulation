import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:json5/json5.dart';

import 'package:heavenly_tribulation/logic/logic.dart';

const kGameLogicExternalDeclarations = '''
external function calculateCostValue(valueData, rank) -> integer
external function calculateCardAffixValue(valueData, {level = 0, rank = 0, greater}) -> integer
external function calculatePassiveAffixValue(valueData, {level = 0, isGreater = false}) -> integer
external function calculatePassiveAffixContribution(valueData, {level = 0, isGreater = false}) -> number
external function calculateItemBasePrice(item) -> integer
external function getMinMaxExtraAffixCount(rank) -> Map
external function minLevelForRank(rank) -> integer
external function maxLevelForRank(rank) -> integer
external function getTribulationCountForRank(rank) -> integer
''';

Hetu createTestHetu({bool relaxedConversions = false}) {
  final hetu = relaxedConversions
      ? Hetu(
          config: HetuConfig(
            allowImplicitNullToZeroConversion: true,
            allowImplicitEmptyValueToFalseConversion: true,
          ),
        )
      : Hetu();
  return hetu..init();
}

void bindGameLogicFunctions(Hetu hetu) {
  void bind(String name,
      dynamic Function({dynamic positionalArgs, dynamic namedArgs}) function) {
    hetu.interpreter.bindExternalFunction(name, function, override: true);
  }

  bind(
      'calculateCostValue',
      ({positionalArgs, namedArgs}) =>
          GameLogic.calculateCostValue(positionalArgs[0], positionalArgs[1]));
  bind(
      'calculateCardAffixValue',
      ({positionalArgs, namedArgs}) => GameLogic.calculateCardAffixValue(
            positionalArgs.first,
            level: namedArgs['level'] ?? 0,
            rank: namedArgs['rank'] ?? 0,
            greater: namedArgs['greater'],
          ));
  bind(
      'calculatePassiveAffixValue',
      ({positionalArgs, namedArgs}) => GameLogic.calculatePassiveAffixValue(
            positionalArgs.first,
            level: namedArgs['level'] ?? 0,
            isGreater: namedArgs['isGreater'] ?? false,
          ));
  bind(
      'calculatePassiveAffixContribution',
      ({positionalArgs, namedArgs}) =>
          GameLogic.calculatePassiveAffixContribution(
            positionalArgs.first,
            level: namedArgs['level'] ?? 0,
            isGreater: namedArgs['isGreater'] ?? false,
          ));
  bind(
      'calculateItemBasePrice',
      ({positionalArgs, namedArgs}) =>
          GameLogic.calculateItemBasePrice(positionalArgs.first));
  bind(
      'getMinMaxExtraAffixCount',
      ({positionalArgs, namedArgs}) =>
          GameLogic.getMinMaxExtraAffixCount(positionalArgs.first));
  bind(
      'minLevelForRank',
      ({positionalArgs, namedArgs}) =>
          GameLogic.minLevelForRank(positionalArgs.first));
  bind(
      'maxLevelForRank',
      ({positionalArgs, namedArgs}) =>
          GameLogic.maxLevelForRank(positionalArgs.first));
  bind(
      'getTribulationCountForRank',
      ({positionalArgs, namedArgs}) =>
          GameLogic.getTribulationCountForRank(positionalArgs.first));
}

Map<String, dynamic> loadJson5File(String path) {
  return Map<String, dynamic>.from(
      json5Decode(File(path).readAsStringSync()) as Map);
}
