import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/ui/view/character/build/build.dart';
import 'package:hetu_script/values.dart';

import '../avatar.dart';
import '../view/character/character.dart';
import '../../global.dart';
import '../shared/bordered_icon_button.dart';
import '../view/character/build/build.dart';
import '../shared/dynamic_color_progressbar.dart';

class HeroInfoPanel extends StatelessWidget {
  const HeroInfoPanel({super.key, required this.heroData});

  final HTStruct heroData;

  @override
  Widget build(BuildContext context) {
    final percentage =
        engine.invoke('getCharacterStats', positionalArgs: [heroData]);

    return Container(
      width: 300,
      height: 120,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius:
            const BorderRadius.only(bottomRight: Radius.circular(5.0)),
        border: Border.all(color: kForegroundColor),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: Avatar(
              name: heroData['name'],
              avatarAssetKey: 'assets/images/${heroData['icon']}',
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (context) {
                  return CharacterView(characterData: heroData);
                },
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale['life']}: ',
                    value: percentage['life'],
                    max: percentage['lifeMax'],
                    width: 100.0,
                    colors: const <Color>[Colors.red, Colors.green],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale['stamina']}: ',
                    value: percentage['stamina'],
                    max: percentage['staminaMax'],
                    width: 100.0,
                    colors: const <Color>[Colors.yellow, Colors.blue],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    BorderedIconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (context) {
                            return BuildView(characterId: heroData['id']);
                          },
                        );
                      },
                      icon: const Image(
                        image: AssetImage('assets/images/icon/inventory02.png'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
