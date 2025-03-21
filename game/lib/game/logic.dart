import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common.dart';
import '../widgets/dialog/timeflow.dart';
import '../scene/game_dialog/selection_dialog.dart';
import '../engine.dart';
import '../scene/game_dialog/game_dialog_content.dart';
import '../widgets/dialog/select_menu.dart';
import '../state/view_panels.dart';
import '../widgets/dialog/input_slider.dart';

import 'data.dart';

/// 根据人物当前境界，获取不同境界卡牌的概率
const kCardObtainProbabilityByRank = {
  '1': {1: 1},
  '2': {
    '1': 0.7,
    '2': 0.3,
  },
  '3': {
    '1': 0.6,
    '2': 0.25,
    '3': 0.15,
  },
  '4': {
    '1': 0.5,
    '2': 0.25,
    '3': 0.15,
    '4': 0.1,
  },
  '5': {
    '1': 0.45,
    '2': 0.25,
    '3': 0.15,
    '4': 0.1,
    '5': 0.05,
  }
};

bool truthy(dynamic) {
  return dynamic != null && dynamic != false;
}

abstract class GameLogic {
  static int expForLevel(level, [difficulty = 1]) {
    return (difficulty * (level) * (level)) * 10 + level * 100 + 40;
  }

  static double gradualValue(num input, num target, {double rate = 0.1}) {
    return target * (1 - math.exp(-rate * input));
  }

  /// 根据角色当前的流派等级和境界，获得三张卡牌
  static List<String> obtainCultivationCards() {
    final List<String> result = [];

    /// genreLevels 是一个数组，代表每个流派的等级
    /// 内容示例：
    /// [
    ///   { genreId: 'flying_sword', probability: 0.7 },
    ///   { genreId: 'dao', probability: 0.2 },
    ///   { genreId: 'avatar', probability: 0.1 },
    ///   ...
    /// ]

    // final probabilityTotal = genreLevels.reduce((a, b) => a.level + b.level);

    // genreLevels.sort((a, b) => b.level.compareTo(a.level));

    return result;
  }

  static bool checkCardRequirement(dynamic characterData, dynamic cardData) {
    if (cardData['isIdentified'] != true) return false;

    final mainAffix = cardData['affixes'][0];
    assert(mainAffix != null);
    final String? equipment = mainAffix['equipment'];
    if (equipment != null) {
      if (characterData['passives']['equipment_$equipment'] == null) {
        return false;
      }
    }
    return true;
  }

  // 返回值依次是：卡组下限，卡组上限，消耗牌上限，持续牌上限
  static (int, int, int, int) getDeckLimitFromRank(int rank) {
    assert(rank >= 0);
    final min = 3;
    final max = rank == 0 ? 3 : rank + 2;
    final ephemeralMax = rank < 5 ? 1 : 2;
    final ongoingMax = rank < 2 ? 0 : 1;
    return (min, max, ephemeralMax, ongoingMax);
  }

  static String? checkDeckRequirement(
      dynamic characterData, List<dynamic> cards) {
    final deckLimit = getDeckLimitFromRank(characterData['rank']);

    if (cards.length < deckLimit.$1) {
      return 'deckbuilding_cards_not_enough';
    }

    for (final card in cards) {
      final valid = checkCardRequirement(characterData, card);
      if (!valid) {
        return 'deckbuilding_card_invalid';
      }
    }

    return null;
  }

  static double getHPRestoreRateAfterBattle(int usedCardCount) {
    assert(usedCardCount > 0);
    return 50 - gradualValue(usedCardCount - 1, 50, rate: 0.1);
  }

  static Future<String?> selectWorldId() async {
    return await showDialog(
      context: engine.context,
      builder: (context) => SelectMenuDialog(
          selections: {for (var element in GameData.worldIds) element: element},
          selectedValue: GameData.worldIds
              .firstWhere((element) => element != GameData.currentWorldId)),
    );
  }

  static void heroRest() async {
    final selected =
        await SelectionDialog.show(engine.context, selectionsData: {
      'selections': {
        'rest1Days': engine.locale('rest1Days'),
        'rest10Days': engine.locale('rest10Days'),
        'rest30Days': engine.locale('rest30Days'),
        'restTillTommorow': engine.locale('restTillTommorow'),
        'restTillNextMonth': engine.locale('restTillNextMonth'),
        'restTillFullHealth': engine.locale('restTillFullHealth'),
        'cancel': engine.locale('cancel'),
      },
    });
    int ticks = 0;
    switch (selected) {
      case 'rest1Days':
        ticks = kTicksPerDay;
      case 'rest10Days':
        ticks = kTicksPerDay * 10;
      case 'rest30Days':
        ticks = kTicksPerDay * 30;
      case 'restTillTommorow':
        ticks = engine.hetu.invoke('getTicksTillNextDay');
      case 'restTillNextMonth':
        ticks = engine.hetu.invoke('getTicksTillNextMonth');
      case 'restTillFullHealth':
        ticks = GameData.heroData['stats']['lifeMax'] -
            GameData.heroData['stats']['life'];
        if (ticks == 0) {
          if (engine.context.mounted) {
            GameDialogContent.show(
                engine.context, engine.locale('alreadyFullHealthNoNeedRest'));
          }
        }
    }

    if (ticks > 0) {
      if (engine.context.mounted) {
        TimeflowDialog.show(
            context: engine.context,
            max: ticks,
            onProgress: () {
              engine.hetu.invoke('restoreLife',
                  namespace: 'Player', positionalArgs: [1]);
            });
      }
    }
  }

  static void onUseItem(itemData) {
    final isIdentified = itemData['isIdentified'] == true;
    if (!isIdentified) {
      GameDialogContent.show(
          engine.context, engine.locale('hint_unidentifiedItem'));
      return;
    }
    if (itemData['useCustomLogic'] == true) {
      engine.hetu
          .invoke('onGameEvent', positionalArgs: ['onUseItem', itemData]);
      return;
    }
    switch (itemData['category']) {
      case 'scroll':
        if (itemData['prototypeId'] == 'identify_scroll') {
          engine.context.read<ViewPanelState>().toogle(
            ViewPanels.itemSelect,
            arguments: {
              'characterData': GameData.heroData,
              'title': engine.locale('selectItem'),
              'filter': {'isIdentified': false},
              'onSelect': (Iterable selectedItemsData) async {
                assert(selectedItemsData.length == 1);
                final selectedItem = selectedItemsData.first;
                selectedItem['isIdentified'] = true;
                engine.play('hammer-hitting-an-anvil-25390.mp3');
                engine.hetu.invoke('lose',
                    namespace: 'Player', positionalArgs: [itemData]);
              },
            },
          );
        }
    }
  }

  static void onChargeItem(itemData) async {
    assert(itemData['chargeData'] != null);
    final chargeData = itemData['chargeData'];
    if (chargeData['current'] >= chargeData['max']) {
      GameDialogContent.show(
          engine.context, engine.locale('hint_itemFullyCharged'));
      return;
    }

    final int shards = GameData.heroData['materials']['shard'];
    final int shardsPerCharge = chargeData['shardsPerCharge'];
    if (shards < shardsPerCharge) {
      GameDialogContent.show(
          engine.context, engine.locale('hint_notEnoughShard'));
      return;
    }

    final int chargeLimit = chargeData['max'] - chargeData['current'];
    assert(chargeLimit > 0);
    final max = math.min(shards ~/ shardsPerCharge, chargeLimit);

    final int? value = await showDialog(
      context: engine.context,
      builder: (context) => InputSliderDialog(
        min: shardsPerCharge,
        max: max * shardsPerCharge,
        divisions: max - 1,
        title: engine.locale('chargeItem'),
        label: engine.locale('shardsCost'),
      ),
    );

    if (value == null) return;

    final charge = value ~/ shardsPerCharge;

    chargeData['current'] += charge;
    engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: [
      'shard'
    ], namedArgs: {
      'amount': value,
    });

    engine.info('物品 ${itemData['name']} 增加了 $charge 充能次数');
    engine.play('electric-sparks-68814.mp3');
  }
}
