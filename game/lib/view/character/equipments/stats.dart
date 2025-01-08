import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
// import 'package:samsara/ui/dynamic_color_progressbar.dart';
import 'package:provider/provider.dart';

import '../../../engine.dart';
import '../../../state/hero.dart';
import '../../../state/hover_info.dart';

const kLabelWidth = 120.0;

class StatsView extends StatelessWidget {
  const StatsView({
    super.key,
    required this.characterData,
    this.isHero = false,
  });

  final dynamic characterData;
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    if (isHero) {
      context.watch<HeroState>().heroData;
    }

    final stats = characterData['stats'];
    final int level = characterData['cultivationLevel'];
    final int rank = characterData['cultivationRank'];
    final int levelMax = characterData['cultivationLevelMax'];
    final String rankString =
        '<rank$rank>${engine.locale('cultivationRank_$rank')}</>';
    final int baseLifeMax = characterData['lifeMax'];
    final int lifeMax = stats['lifeMax'];
    final int lightRadius = stats['lightRadius'];
    final int spirituality = stats['spirituality'];
    final int dexterity = stats['dexterity'];
    final int strength = stats['strength'];
    final int willpower = stats['willpower'];
    final int perception = stats['perception'];
    final int unarmedAttack = stats['unarmedAttack'];
    final int weaponAttack = stats['weaponAttack'];
    final int spellAttack = stats['spellAttack'];
    final int curseAttack = stats['curseAttack'];
    final int poisonAttack = stats['poisonAttack'];
    final int physicalResist = stats['physicalResist'];
    final int chiResist = stats['chiResist'];
    final int elementalResist = stats['elementalResist'];
    final int spiritualResist = stats['spiritualResist'];
    // final int quickThreshold = stats['quickThreshold'];
    // final int slowThreshold = stats['slowThreshold'];
    // final int nimbleThreshold = stats['nimbleThreshold'];
    // final int clumsyThreshold = stats['clumsyThreshold'];

    final labels = <Widget>[
      Label(
        '${engine.locale('cultivationLevel')}: $level',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text =
              '${engine.locale('levelMax')}: $levelMax\n${engine.locale('cultivationLevel_description')}';
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('cultivationRank')}: $rankString',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('cultivationRank_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('lifeMax')}: ${lifeMax > baseLifeMax ? '<yellow>$lifeMax</>' : lifeMax.toString()}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('lifeMax_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('lightRadius')}: $lightRadius',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('lightRadius_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      const Divider(),
      Label(
        '${engine.locale('dexterity')}: $dexterity',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('dexterity_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('spirituality')}: $spirituality',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('spirituality_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('strength')}: $strength',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('strength_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('perception')}: $perception',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('perception_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('willpower')}: $willpower',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('willpower_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      const Divider(),
      Label(
        '${engine.locale('unarmedAttack')}: ${unarmedAttack > 0 ? '<yellow>$unarmedAttack</>' : unarmedAttack}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('attack_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('weaponAttack')}: ${weaponAttack > 0 ? '<yellow>$weaponAttack</>' : weaponAttack}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('attack_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('spellAttack')}: ${spellAttack > 0 ? '<yellow>$spellAttack</>' : spellAttack}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('attack_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('curseAttack')}: ${curseAttack > 0 ? '<yellow>$curseAttack</>' : curseAttack}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('attack_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('poisonAttack')}: ${poisonAttack > 0 ? '<yellow>$poisonAttack</>' : poisonAttack}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('attack_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('physicalResist')}: ${physicalResist > 0 ? '<yellow>$physicalResist</>' : physicalResist}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('resist_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('chiResist')}: ${chiResist > 0 ? '<yellow>$chiResist</>' : chiResist}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('resist_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('elementalResist')}: ${elementalResist > 0 ? '<yellow>$elementalResist</>' : elementalResist}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('resist_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
      Label(
        '${engine.locale('spiritualResist')}: ${spiritualResist > 0 ? '<yellow>$spiritualResist</>' : spiritualResist}',
        width: kLabelWidth,
        textAlign: TextAlign.left,
        onMouseEnter: (rect) {
          final text = engine.locale('resist_description');
          context.read<HoverInfoContentState>().set(text, rect);
        },
        onMouseExit: () {
          context.read<HoverInfoContentState>().hide();
        },
      ),
    ];

    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 10.0, top: 5.0, right: 5.0),
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: labels,
        ),
      ),
    );
  }
}
