import 'package:flutter/material.dart';
import 'package:samsara/extensions.dart';
import 'package:provider/provider.dart';

import 'engine.dart';
import 'common.dart';
import 'state/hero.dart';

dynamic resetHero(BuildContext context) {
  final heroData = engine.hetu.invoke('Character', namedArgs: {
    'unconvertedExp': 1000000,
    // 'isFemale': false,
    'cultivationLevel': 10,
    'cultivationRank': 1,
    'availableSkillPoints': 10,
  });
  engine.hetu.invoke('setHeroId', positionalArgs: [heroData['id']]);
  context.read<HeroState>().update();

  for (var i = 0; i < 6; ++i) {
    final cardPack = engine.hetu.invoke('CardPack');
    engine.hetu.invoke('acquire', namespace: 'Player', positionalArgs: [
      cardPack,
    ]);
  }

  // for (var i = 0; i < 24; ++i) {
  //   final cardData = engine.hetu.invoke(
  //     'BattleCard',
  //     namedArgs: {
  //       // 'level': heroData['cultivationLevel'],
  //       'maxRank': heroData['cultivationRank'],
  //       'isIdentified': true,
  //     },
  //   );
  //   engine.hetu
  //       .invoke('acquire', namespace: 'Player', positionalArgs: [cardData]);
  // }

  for (var i = 0; i < 6; ++i) {
    final kind = kWeaponKinds.random();
    final itemData = engine.hetu.invoke('Equipment', namedArgs: {
      'kind': kind,
      // 'level': heroData['cultivationLevel'],
      'rank': heroData['cultivationRank'],
    });

    engine.hetu.invoke('acquire', namespace: 'Player', positionalArgs: [
      itemData,
    ]);
  }

  return heroData;
}
