import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
// import 'package:samsara/ui/dynamic_color_progressbar.dart';

import '../../../config.dart';

class StatsView extends StatelessWidget {
  const StatsView({
    super.key,
    required this.characterData,
    this.useColumn = false,
  });

  final dynamic characterData;
  final bool useColumn;

  @override
  Widget build(BuildContext context) {
    final stats = characterData['stats'];
    final int lifeMax = stats['lifeMax'];
    final int staminaMax = stats['staminaMax'];
    final int manaMax = stats['manaMax'];
    final int spirituality = stats['spirituality'];
    final int dexterity = stats['dexterity'];
    final int strength = stats['strength'];
    final int willpower = stats['willpower'];
    final int perception = stats['perception'];
    final int armor = stats['armor'];
    final int weaponAttack = stats['weaponAttack'];

    final labels = <Widget>[
      Label(
        '${engine.locale('spirituality')}: $spirituality',
        width: 120.0,
      ),
      Label(
        '${engine.locale('dexterity')}: $dexterity',
        width: 120.0,
      ),
      Label(
        '${engine.locale('strength')}: $strength',
        width: 120.0,
      ),
      Label(
        '${engine.locale('willpower')}: $willpower',
        width: 120.0,
      ),
      Label(
        '${engine.locale('perception')}: $perception',
        width: 120.0,
      ),
      Label(
        '${engine.locale('lifeMax')}: $lifeMax',
        width: 120.0,
      ),
      Label(
        '${engine.locale('manaMax')}: $manaMax',
        width: 120.0,
      ),
      Label(
        '${engine.locale('staminaMax')}: $staminaMax',
        width: 120.0,
      ),
      Label(
        '${engine.locale('armor')}: $armor',
        width: 120.0,
      ),
      Label(
        '${engine.locale('weaponAttack')}: $weaponAttack',
        width: 120.0,
      ),
    ];

    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 10.0, top: 5.0, right: 5.0),
        width: 240,
        child: useColumn
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: labels,
              )
            : Wrap(
                children: labels,
              ),
      ),
    );
  }
}
