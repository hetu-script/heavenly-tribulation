import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/tilemap.dart';

import '../avatar.dart';
import '../view/character/information/character.dart';
import '../../global.dart';
import '../shared/bordered_icon_button.dart';
import '../view/character/builds/build.dart';
import '../shared/dynamic_color_progressbar.dart';
import '../view/character/stats/stats.dart';

class HeroInfoPanel extends StatelessWidget {
  const HeroInfoPanel({
    super.key,
    required this.heroData,
    this.showTilePosition = true,
    this.currentTerrain,
    this.currentNationData,
    this.currentLocationData,
  });

  final HTStruct heroData;
  final bool showTilePosition;
  final TileMapTerrain? currentTerrain;
  final HTStruct? currentNationData;
  final HTStruct? currentLocationData;

  @override
  Widget build(BuildContext context) {
    final charStats =
        engine.invoke('getCharacterStats', positionalArgs: [heroData]);

    final sb = StringBuffer();

    sb.write(
        '${heroData['worldPosition']['left']}, ${heroData['worldPosition']['top']}');

    if (currentLocationData != null) {
      sb.write(' - ');
      sb.write(currentLocationData!['name']);
    } else if (currentTerrain != null) {
      sb.write(' - ');
      sb.write(engine.locale[currentTerrain!.kind!]);
    }

    if (currentNationData != null) {
      sb.write(', ');
      sb.write(currentNationData!['name']);
    }

    return Container(
      width: 298,
      height: 130,
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
              name: heroData['name'],
              avatarAssetKey: 'assets/images/${heroData['icon']}',
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
                    width: 100.0,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.red, Colors.green],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale['stamina']}: ',
                    value: charStats['stamina'],
                    max: charStats['staminaMax'],
                    width: 100.0,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.yellow, Colors.blue],
                  ),
                ),
                if (showTilePosition)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Text(sb.toString()),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
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
                          image:
                              AssetImage('assets/images/icon/information.png'),
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
                          image: AssetImage('assets/images/icon/status.png'),
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
                          image: AssetImage('assets/images/icon/inventory.png'),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text(
                            '${engine.locale['money']}: ${heroData['money']}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
