import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/flutter_ui/bordered_icon_button.dart';
import 'package:samsara/flutter_ui/dynamic_color_progressbar.dart';

import '../avatar.dart';
import '../view/character/information/character.dart';
import '../../global.dart';
import '../view/character/builds/build.dart';
import '../view/character/stats/status.dart';

const kStatsBarWidth = 125.0;

class HeroInfoPanel extends StatelessWidget {
  const HeroInfoPanel({
    super.key,
    required this.heroData,
  });

  final HTStruct heroData;

  @override
  Widget build(BuildContext context) {
    final charStats =
        engine.invoke('getCharacterStats', positionalArgs: [heroData]);

    return Container(
      width: 328,
      height: 150,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        // borderRadius:
        //     const BorderRadius.only(bottomRight: Radius.circular(5.0)),
        border: Border.all(color: kForegroundColor),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: Avatar(
              size: const Size(120, 120),
              name: heroData['name'],
              image: AssetImage('assets/images/${heroData['icon']}'),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale['life']}: ',
                    value: charStats['life'],
                    max: charStats['lifeMax'],
                    width: kStatsBarWidth,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.red, Colors.red],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale['stamina']}: ',
                    value: charStats['stamina'],
                    max: charStats['staminaMax'],
                    width: kStatsBarWidth,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.blue, Colors.blue],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale['mana']}: ',
                    value: charStats['mana'],
                    max: charStats['manaMax'],
                    width: kStatsBarWidth,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.yellow, Colors.yellow],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale['spirit']}: ',
                    value: charStats['spirit'],
                    max: charStats['spiritMax'],
                    width: kStatsBarWidth,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.green, Colors.green],
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Row(
                        children: [
                          BorderedIconButton(
                            padding: const EdgeInsets.only(right: 5.0),
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (context) =>
                                    CharacterView(characterData: heroData),
                              );
                            },
                            tooltip: engine.locale['information'],
                            icon: const Image(
                              image: AssetImage(
                                  'assets/images/icon/information.png'),
                            ),
                          ),
                          BorderedIconButton(
                            padding: const EdgeInsets.only(right: 5.0),
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (context) =>
                                    StatusView(characterData: heroData),
                              );
                            },
                            tooltip: engine.locale['status'],
                            icon: const Image(
                              image:
                                  AssetImage('assets/images/icon/status.png'),
                            ),
                          ),
                          BorderedIconButton(
                            padding: const EdgeInsets.only(right: 5.0),
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (context) =>
                                    BuildView(characterData: heroData),
                              );
                            },
                            tooltip: engine.locale['build'],
                            icon: const Image(
                              image: AssetImage(
                                  'assets/images/icon/inventory.png'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expanded(
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(5.0),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //       children: [
                    //         Text('${engine.locale['money']}:'),
                    //         Text('${heroData['money']}'),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
