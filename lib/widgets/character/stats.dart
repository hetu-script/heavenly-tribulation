import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
// import 'package:samsara/ui/dynamic_color_progressbar.dart';
import 'package:provider/provider.dart';

import '../../engine.dart';
import '../../state/character.dart';
import '../../state/hover_content.dart';
import '../../common.dart';
import '../../game/logic.dart';

const kStatsItems = [
  'level',
  'rank',
  'tribulationCount',
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
  'unarmedEnhance',
  'weaponEnhance',
  'spellEnhance',
  'curseEnhance',
  'physicalResist',
  'chiResist',
  'elementalResist',
  'psychicResist',
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
    required this.characterData,
    this.isHero = false,
    this.showNonBattleStats = true,
    this.width = 220.0,
    this.height,
  });

  final String? title;
  final dynamic characterData;
  final bool isHero;
  final bool showNonBattleStats;
  final double width;
  final double? height;

  @override
  State<CharacterStats> createState() => _CharacterStatsState();
}

class _CharacterStatsState extends State<CharacterStats> {
  Widget getStatsLabel(String id) {
    if (id == 'divider') return const Divider();

    final int baseValue = widget.characterData[id] ?? 0;
    final int value = widget.characterData['stats'][id] ?? 0;

    String description;
    if (id == 'level') {
      final int levelMax =
          GameLogic.maxLevelForRank(widget.characterData['rank']);
      description =
          '${engine.locale('levelMax')}: $levelMax\n${engine.locale('level_description')}';
    } else if (id.endsWith('Resist') || id == 'tribulationCount') {
      final int baseValueMax =
          widget.characterData['${id}Max'] ?? kBaseResistMax;
      final int valueMax =
          widget.characterData['stats']?['${id}Max'] ?? kBaseResistMax;

      final maxString =
          (valueMax > baseValueMax ? '<yellow>$valueMax</>' : valueMax)
              .toString();

      description =
          '${engine.locale('${id}Max')}: $maxString\n${engine.locale('${id}_description')}';
    } else {
      description = engine.locale('${id}_description');
    }

    String valueString;
    if (id == 'rank') {
      final int rank = widget.characterData['rank'];
      valueString = '<rank$rank>${engine.locale('cultivationRank_$rank')}</>';
    } else if (id == 'level' || id == 'karma') {
      valueString = baseValue.toString();
    } else {
      valueString =
          (value > baseValue ? '<yellow>$value</>' : value).toString();
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
    if (widget.isHero) {
      context.watch<HeroState>().heroData;
    }

    final List<Widget> items = [];
    if (widget.title != null) {
      items.add(Label(
        widget.title!,
        width: widget.width,
        textAlign: TextAlign.left,
      ));
      items.add(const Divider());
    }

    final length = widget.showNonBattleStats
        ? kStatsItems.length
        : kStatsItems.length - kNonBattleItemsLength;
    for (var i = 0; i < length; ++i) {
      final id = kStatsItems[i];
      items.add(getStatsLabel(id));
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
