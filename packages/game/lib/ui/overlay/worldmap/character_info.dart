import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/ui/view/character/build/build.dart';
import 'package:hetu_script/values.dart';

import '../../shared/avatar.dart';
import '../../view/character/character.dart';
import '../../../global.dart';
import '../../shared/bordered_icon_button.dart';
import '../../view/character/build/build.dart';
import '../../shared/dynamic_color_progressbar.dart';

class HeroInfoPanel extends StatelessWidget {
  const HeroInfoPanel({Key? key, required this.heroData}) : super(key: key);

  final HTStruct heroData;

  @override
  Widget build(BuildContext context) {
    final percentage = engine
        .invoke('getStatsPercentageOfCharacter', positionalArgs: [heroData]);

    return Container(
      width: 260,
      height: 120,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: GlobalConfig.theme.backgroundColor,
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
              avatarAssetKey: 'assets/images/${heroData['avatar']}',
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.transparent,
                builder: (context) {
                  return CharacterView(characterId: heroData['id']);
                },
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                DynamicColorProgressBar(
                  title: '${engine.locale['life']}: ',
                  value: percentage['life']['percentage'],
                  size: const Size(100.0, 24.0),
                  colors: const <Color>[Colors.red, Colors.green],
                ),
                DynamicColorProgressBar(
                  title: '${engine.locale['stamina']}: ',
                  value: percentage['life']['percentage'],
                  size: const Size(100.0, 24.0),
                  colors: const <Color>[Colors.yellow, Colors.blue],
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
                        image: AssetImage('assets/images/icon/build.png'),
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
