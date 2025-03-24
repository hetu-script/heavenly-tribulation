import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
// import 'package:samsara/ui/dynamic_color_progressbar.dart';
import 'package:provider/provider.dart';

import '../../../engine.dart';
import '../../../state/character.dart';
import '../../../state/hoverinfo.dart';

const kLabelWidth = 120.0;

class CharacterStats extends StatelessWidget {
  const CharacterStats({
    super.key,
    required this.characterData,
    this.isHero = false,
    this.showNonBattleStats = true,
  });

  final dynamic characterData;
  final bool isHero;
  final bool showNonBattleStats;

  @override
  Widget build(BuildContext context) {
    if (isHero) {
      context.watch<HeroState>().heroData;
    }

    final int level = characterData['level'];
    final int rank = characterData['rank'];
    final int levelMax = characterData['levelMax'];
    final String rankString =
        '<rank$rank>${engine.locale('cultivationRank_$rank')}</>';
    final stats = characterData['stats'];
    // final identifedStats = characterData['identifiedStats'];
    final int baseLifeMax = characterData['lifeMax'];
    final int baseLightRadius = characterData['lightRadius'];
    final int baseSpirituality = characterData['spirituality'];
    final int baseDexterity = characterData['dexterity'];
    final int baseStrength = characterData['strength'];
    final int baseWillpower = characterData['willpower'];
    final int basePerception = characterData['perception'];
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
    // final bool isUnarmedAttackIdentified =
    //     identifedStats['unarmedAttack'] ?? false;
    // final bool isWeaponAttackIdentified =
    //     identifedStats['weaponAttack'] ?? false;
    // final bool isSpellAttackIdentified = identifedStats['spellAttack'] ?? false;
    // final bool isCurseAttackIdentified = identifedStats['curseAttack'] ?? false;
    // final bool isPoisonAttackIdentified =
    //     identifedStats['poisonAttack'] ?? false;
    // final bool isPhysicalResistIdentified =
    //     identifedStats['physicalResist'] ?? false;
    // final bool isChiResistIdentified = identifedStats['chiResist'] ?? false;
    // final bool isElementalResistIdentified =
    //     identifedStats['elementalResist'] ?? false;
    // final bool isSpiritualResistIdentified =
    //     identifedStats['spiritualResist'] ?? false;

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
      const Divider(),
      Label(
        '${engine.locale('dexterity')}: ${dexterity > baseDexterity ? '<yellow>$dexterity</>' : dexterity}',
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
        '${engine.locale('spirituality')}: ${spirituality > baseSpirituality ? '<yellow>$spirituality</>' : spirituality}',
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
        '${engine.locale('perception')}: ${perception > basePerception ? '<yellow>$perception</>' : perception}',
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
        '${engine.locale('strength')}: ${strength > baseStrength ? '<yellow>$strength</>' : strength}',
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
        '${engine.locale('willpower')}: ${willpower > baseWillpower ? '<yellow>$willpower</>' : willpower}',
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
        // (isHero) // || isUnarmedAttackIdentified)
        // ?
        '${engine.locale('unarmedAttack')}: ${unarmedAttack > 0 ? '<yellow>$unarmedAttack</>' : unarmedAttack}',
        // : '???',
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
        // (isHero) // || isWeaponAttackIdentified)
        // ?
        '${engine.locale('weaponAttack')}: ${weaponAttack > 0 ? '<yellow>$weaponAttack</>' : weaponAttack}',
        // : '???',
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
        // (isHero) // || isSpellAttackIdentified)
        // ?
        '${engine.locale('spellAttack')}: ${spellAttack > 0 ? '<yellow>$spellAttack</>' : spellAttack}',
        // : '???',
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
        // (isHero) // || isCurseAttackIdentified)
        // ?
        '${engine.locale('curseAttack')}: ${curseAttack > 0 ? '<yellow>$curseAttack</>' : curseAttack}',
        // : '???',
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
        // (isHero) // || isPoisonAttackIdentified)
        // ?
        '${engine.locale('poisonAttack')}: ${poisonAttack > 0 ? '<yellow>$poisonAttack</>' : poisonAttack}',
        // : '???',
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
        // (isHero) // || isPhysicalResistIdentified)
        // ?
        '${engine.locale('physicalResist')}: ${physicalResist > 0 ? '<yellow>$physicalResist</>' : physicalResist}',
        // : '???',
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
        // (isHero) // || isChiResistIdentified)
        // ?
        '${engine.locale('chiResist')}: ${chiResist > 0 ? '<yellow>$chiResist</>' : chiResist}',
        // : '???',
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
        // (isHero) // || isElementalResistIdentified)
        // ?

        '${engine.locale('elementalResist')}: ${elementalResist > 0 ? '<yellow>$elementalResist</>' : elementalResist}',
        // : '???',
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
        // (isHero) // || isSpiritualResistIdentified)
        // ?
        '${engine.locale('spiritualResist')}: ${spiritualResist > 0 ? '<yellow>$spiritualResist</>' : spiritualResist}',
        // : '???',
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
      if (showNonBattleStats) ...[
        const Divider(),
        Label(
          '${engine.locale('lightRadius')}: ${lightRadius > baseLightRadius ? '<yellow>$lightRadius</>' : lightRadius}',
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
      ]
    ];

    return ScrollConfiguration(
      behavior: MaterialScrollBehavior(),
      child: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(5.0),
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: labels,
          ),
        ),
      ),
    );
  }
}
