import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:samsara/hover_info.dart';

import '../../global.dart';
import '../../logic/logic.dart';
import '../../data/common.dart';

const kStats = [
  'level',
  'rank',
  'divider',
  'dexterity',
  'strength',
  'spirituality',
  'willpower',
  'perception',
  'divider',
  'lifeMax',
  'battleLifeMax',
  'manaMax',
  'chakraMax',
  'karma',
  'karmaMax',
  'divider',
  'unarmedAttack',
  'weaponAttack',
  'spellAttack',
  'curseAttack',
  'physicalResist',
  'chiResist',
  'elementalResist',
  'psychicResist',
];

const kMoreStats = [
  'divider',
  'quickThreshold',
  'slowThreshold',
  'nimbleThreshold',
  'clumsyThreshold',
  'divider',
  'monthlyIdentifyCardsMax',
  'lightRadius',
  'plainMoveSpeed',
  'mountainMoveSpeed',
  'waterMoveSpeed',
  'mountainMoveStaminaCost',
  'waterMoveStaminaCost',
  'expCollectSpeed',
  'expGainPerLight',
  'staminaCostWork',
  'workEfficiency',
  'craftEfficiency',
];

const kNonBattleItemsLength = 4;

class CharacterStats extends StatefulWidget {
  const CharacterStats({
    super.key,
    this.title,
    this.character,
    this.showNonBattleStats = true,
    this.width = 220.0,
    this.height,
  });

  final String? title;
  final dynamic character;
  final bool showNonBattleStats;
  final double width;
  final double? height;

  @override
  State<CharacterStats> createState() => _CharacterStatsState();
}

class _CharacterStatsState extends State<CharacterStats> {
  Widget _buildStatsLabel(String id, dynamic character) {
    if (id == 'divider') return const Divider();

    final num baseValue = character[id] ?? 0;
    final num value = character['stats'][id] ?? baseValue;

    String idString = engine.locale(id);
    String valueString;
    String description;
    if (id == 'tribulationCount') {
      final int baseValueMax = character['${id}Max'];
      final int valueMax = character['stats']?['${id}Max'];
      final maxString = valueMax > baseValueMax
          ? '<yellow>$valueMax</>'
          : valueMax.toString();
      valueString = '$value/$maxString';
      description = engine.locale('stats_${id}_description');
    } else if (id == 'level') {
      valueString = baseValue.toString();
      final int levelMax = GameLogic.maxLevelForRank(character['rank']);
      description =
          '${engine.locale('stats_level_description')}\n${engine.locale('stats_levelMax')}: $levelMax';
    } else if (id == 'rank') {
      final int rank = character['rank'];
      valueString = '<rank$rank>${engine.locale('cultivationRank_$rank')}</>';
      description = engine.locale('stats_${id}_description');
    } else if (id.endsWith('Attack')) {
      valueString = value > baseValue ? '<yellow>$value%</>' : '$value%';
      description = engine.locale('stats_${id}_description');
    } else if (id.endsWith('Resist')) {
      final int baseValueMax = character['${id}Max'];
      final int valueMax = character['stats']?['${id}Max'];

      final maxString = valueMax > baseValueMax
          ? '<yellow>$valueMax</>'
          : valueMax.toString();

      valueString = value > baseValue ? '<yellow>$value%</>' : '$value%';
      description = engine.locale('stats_${id}_description');
      '${engine.locale('stats_${id}_description')}\n${engine.locale('stats_${id}Max')}: $maxString%';
    } else if (id.endsWith('Threshold')) {
      valueString = value < baseValue ? '<yellow>$value</>' : value.toString();
      description = engine.locale('stats_${id}_description');
    } else if (id.endsWith('Speed')) {
      final baseTimeCost = kTicksPerTime ~/ baseValue;
      final timeCost = kTicksPerTime ~/ value;
      valueString = timeCost < baseTimeCost
          ? '<yellow>$timeCost</>'
          : timeCost.toString();
      description = engine
          .locale('stats_${id.replaceAll('Speed', 'TimeCost')}_description');
    } else if (id == 'craftEfficiency' ||
        id == 'workEfficiency' ||
        id == 'staminaCostWork') {
      valueString = '${(value * 100).toStringAsFixed(0)}%';
      description = engine.locale('stats_${id}_description');
    } else {
      valueString = value > baseValue ? '<yellow>$value</>' : value.toString();
      description = engine.locale('stats_${id}_description');
    }

    return Label(
      '$idString: $valueString',
      width: widget.width,
      textAlign: TextAlign.left,
      onMouseEnter: (rect) {
        context.read<HoverContentState>().show(rect: rect, data: description);
      },
      onMouseExit: () {
        context.read<HoverContentState>().hide();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    if (widget.title != null) {
      items.add(Label(
        widget.title!,
        width: widget.width,
        textAlign: TextAlign.left,
      ));
      items.add(const Divider());
    }

    if (widget.character['rank'] > 0) {
      items.add(_buildStatsLabel('tribulationCount', widget.character));
    }
    for (final id in kStats) {
      items.add(_buildStatsLabel(id, widget.character));
    }

    if (widget.showNonBattleStats) {
      for (final id in kMoreStats) {
        items.add(_buildStatsLabel(id, widget.character));
      }
    }

    return ScrollConfiguration(
      behavior: MaterialScrollBehavior(),
      child: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(5.0),
          width: widget.width,
          height: widget.height,
          child: ListView(
            shrinkWrap: true,
            children: items,
          ),
        ),
      ),
    );
  }
}
