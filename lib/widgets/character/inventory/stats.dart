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
    final int unarmedEnhance = stats['unarmedEnhance'];
    final int weaponEnhance = stats['weaponEnhance'];
    final int spellEnhance = stats['spellEnhance'];
    final int curseEnhance = stats['curseEnhance'];
    final int chaosEnhance = stats['chaosEnhance'];
    final int physicalResist = stats['physicalResist'];
    final int chiResist = stats['chiResist'];
    final int elementalResist = stats['elementalResist'];
    final int spiritualResist = stats['spiritualResist'];
    // final int quickThreshold = stats['quickThreshold'];
    // final int slowThreshold = stats['slowThreshold'];
    // final int nimbleThreshold = stats['nimbleThreshold'];
    // final int clumsyThreshold = stats['clumsyThreshold'];
    // final bool isUnarmedAttackIdentified =
    //     identifedStats['unarmedEnhance'] ?? false;
    // final bool isWeaponAttackIdentified =
    //     identifedStats['weaponEnhance'] ?? false;
    // final bool isSpellAttackIdentified = identifedStats['spellEnhance'] ?? false;
    // final bool isCurseAttackIdentified = identifedStats['curseEnhance'] ?? false;
    // final bool isPoisonAttackIdentified =
    //     identifedStats['poisonEnhance'] ?? false;
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
        '${engine.locale('unarmedEnhance')}: ${unarmedEnhance > 0 ? '<yellow>$unarmedEnhance</>' : unarmedEnhance}',
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
        '${engine.locale('weaponEnhance')}: ${weaponEnhance > 0 ? '<yellow>$weaponEnhance</>' : weaponEnhance}',
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
        '${engine.locale('spellEnhance')}: ${spellEnhance > 0 ? '<yellow>$spellEnhance</>' : spellEnhance}',
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
        '${engine.locale('curseEnhance')}: ${curseEnhance > 0 ? '<yellow>$curseEnhance</>' : curseEnhance}',
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
        '${engine.locale('chaosEnhance')}: ${chaosEnhance > 0 ? '<yellow>$chaosEnhance</>' : chaosEnhance}',
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
