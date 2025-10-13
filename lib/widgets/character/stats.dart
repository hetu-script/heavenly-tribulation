import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
// import 'package:samsara/ui/dynamic_color_progressbar.dart';
import 'package:provider/provider.dart';

import '../../engine.dart';
import '../../state/character.dart';
import '../../state/hover_content.dart';
import '../../game/logic/logic.dart';

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

const kNonBattleStats = [
  'divider',
  'lightRadius',
  'expCollectEfficiency',
  'identifyCardsCountMonthly',
];

const kNonBattleItemsLength = 4;

class CharacterStats extends StatefulWidget {
  const CharacterStats({
    super.key,
    this.title,
    this.character,
    this.isHero = false,
    this.showNonBattleStats = true,
    this.width = 220.0,
    this.height,
  }) : assert(character != null || isHero);

  final String? title;
  final dynamic character;
  final bool isHero;
  final bool showNonBattleStats;
  final double width;
  final double? height;

  @override
  State<CharacterStats> createState() => _CharacterStatsState();
}

class _CharacterStatsState extends State<CharacterStats> {
  Widget _buildStatsLabel(String id, dynamic data) {
    if (id == 'divider') return const Divider();

    final int baseValue = data[id] ?? 0;
    final int value = data['stats'][id] ?? baseValue;

    String valueString;
    String description;
    if (id == 'tribulationCount') {
      final int baseValueMax = data['${id}Max'];
      final int valueMax = data['stats']?['${id}Max'];
      final maxString = valueMax > baseValueMax
          ? '<yellow>$valueMax</>'
          : valueMax.toString();
      valueString = '$value/$maxString';
      description = engine.locale('${id}_description');
    } else if (id == 'rank') {
      final int rank = data['rank'];
      valueString = '<rank$rank>${engine.locale('cultivationRank_$rank')}</>';
      description = engine.locale('${id}_description');
    } else if (id == 'level' || id == 'karma') {
      valueString = baseValue.toString();
      final int levelMax = GameLogic.maxLevelForRank(data['rank']);
      description =
          '${engine.locale('level_description')}\n${engine.locale('levelMax')}: $levelMax';
    } else if (id.endsWith('Resist')) {
      final int baseValueMax = data['${id}Max'];
      final int valueMax = data['stats']?['${id}Max'];

      final maxString = valueMax > baseValueMax
          ? '<yellow>$valueMax</>'
          : valueMax.toString();

      valueString = '$value%';
      description =
          '${engine.locale('${id}_description')}\n${engine.locale('${id}Max')}: $maxString%';
    } else {
      valueString = value > baseValue ? '<yellow>$value</>' : value.toString();
      description = engine.locale('${id}_description');
    }

    return Label(
      '${engine.locale(id)}: $valueString',
      width: widget.width,
      textAlign: TextAlign.left,
      onMouseEnter: (rect) {
        context.read<HoverContentState>().show(description, rect);
      },
      onMouseExit: () {
        context.read<HoverContentState>().hide();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    dynamic data =
        widget.isHero ? context.watch<GameState>().hero : widget.character;
    assert(data != null);

    final List<Widget> items = [];
    if (widget.title != null) {
      items.add(Label(
        widget.title!,
        width: widget.width,
        textAlign: TextAlign.left,
      ));
      items.add(const Divider());
    }

    if (data['rank'] > 0) {
      items.add(_buildStatsLabel('tribulationCount', data));
    }

    for (final id in kStats) {
      items.add(_buildStatsLabel(id, data));
    }

    if (widget.showNonBattleStats) {
      for (final id in kNonBattleStats) {
        items.add(_buildStatsLabel(id, data));
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
