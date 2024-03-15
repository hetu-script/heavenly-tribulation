import 'package:flutter/material.dart';
// import 'package:hetu_script/values.dart';
import 'package:samsara/ui/bordered_icon_button.dart';
import 'package:samsara/ui/dynamic_color_progressbar.dart';
// import 'package:samsara/tilemap.dart';
import 'package:provider/provider.dart';

import '../view/avatar.dart';
import '../view/character/profile.dart';
import '../view/character/memory.dart';
import '../config.dart';
// import '../ui/view/character/_obselete/build.dart';
import '../view/character/equipments.dart';
import '../state/tile_info.dart';

const tickName = {
  1: 'morning.jpg',
  2: 'afternoon.jpg',
  3: 'evening.jpg',
  4: 'night.jpg',
};

class HeroInfoPanel extends StatelessWidget {
  const HeroInfoPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hero = context.watch<SelectedTileState>().hero;
    final currentZone = context.watch<SelectedTileState>().currentZone;
    final currentNation = context.watch<SelectedTileState>().currentNation;
    final currentLocation = context.watch<SelectedTileState>().currentLocation;
    final currentTerrain = context.watch<SelectedTileState>().currentTerrain;

    final dateString = engine.hetu.invoke('getCurrentDateTimeString');
    // final tick = engine.hetu.fetch('ticksOfDay');

    final money = (hero?['materials']['money']).toString();
    final spiritStone = (hero?['materials']['spiritStone']).toString();

    final sb2 = StringBuffer();
    if (currentZone != null) {
      sb2.write('${currentZone!['name']}, ');
    }
    if (currentNation != null) {
      sb2.write('${currentNation['name']}, ');
    }
    if (currentLocation != null) {
      sb2.write('${currentLocation['name']}, ');
    }
    if (currentTerrain != null) {
      sb2.write(
          '${engine.locale(currentTerrain.kind!)}, ${currentTerrain.left}, ${currentTerrain.top}');
    }

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container(
            //   width: 130,
            //   height: 130,
            //   padding: const EdgeInsets.all(5.0),
            //   decoration: BoxDecoration(
            //     color: kBackgroundColor,
            //     borderRadius: BorderRadius.circular(10.0),
            //     // border: Border.all(color: kForegroundColor),
            //   ),
            //   child:
            Avatar(
              color: kBackgroundColor,
              size: const Size(120, 120),
              // displayName: hero['name'],
              image: AssetImage('assets/images/avatar/${hero['icon']}'),
            ),
            // ),
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(12.0),
            //   child:

            Container(
              width: 420,
              height: 80,
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: kForegroundColor),
              ),
              child: Stack(
                children: [
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: CustomPaint(
                  //     painter: LinearPainter(
                  //       beginPosition: Alignment.centerLeft,
                  //       endPosition: Alignment.centerRight,
                  //     ),
                  //     child: Image(
                  //       image:
                  //           AssetImage('assets/images/clock/${tickName[tick]}'),
                  //       opacity: const AlwaysStoppedAnimation(0.1),
                  //     ),
                  //   ),
                  // ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: DynamicColorProgressBar(
                                  title: '${engine.locale('life')}:',
                                  value: hero['stats']['life'],
                                  max: hero['stats']['lifeMax'],
                                  height: 16.0,
                                  width: 155.0,
                                  showNumber: false,
                                  showNumberAsPercentage: false,
                                  colors: <Color>[
                                    Colors.red.shade400,
                                    Colors.red.shade900
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: DynamicColorProgressBar(
                                  title: '${engine.locale('stamina')}:',
                                  value: hero['stats']['stamina'],
                                  max: hero['stats']['staminaMax'],
                                  height: 16.0,
                                  width: 155.0,
                                  showNumber: false,
                                  showNumberAsPercentage: false,
                                  colors: const <Color>[
                                    Colors.yellow,
                                    Colors.green
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2.5),
                                child: DynamicColorProgressBar(
                                  title: '${engine.locale('mana')}:',
                                  value: hero['stats']['mana'],
                                  max: hero['stats']['manaMax'],
                                  height: 16.0,
                                  width: 155.0,
                                  showNumber: false,
                                  showNumberAsPercentage: false,
                                  colors: const <Color>[
                                    Colors.yellow,
                                    Colors.green
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateString),
                            Text(sb2.toString()),
                            Row(
                              children: [
                                BorderedIconButton(
                                  size: const Size(20.0, 20.0),
                                  padding: const EdgeInsets.only(right: 5.0),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors.transparent,
                                      builder: (context) =>
                                          ProfileView(characterData: hero),
                                    );
                                  },
                                  tooltip: engine.locale('information'),
                                  icon: const Image(
                                    image: AssetImage(
                                        'assets/images/icon/information.png'),
                                  ),
                                ),
                                BorderedIconButton(
                                  size: const Size(20.0, 20.0),
                                  padding: const EdgeInsets.only(right: 5.0),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors.transparent,
                                      builder: (context) =>
                                          EquipmentsView(characterData: hero),
                                    );
                                  },
                                  tooltip: engine.locale('build'),
                                  icon: const Image(
                                    image: AssetImage(
                                        'assets/images/icon/inventory.png'),
                                  ),
                                ),
                                BorderedIconButton(
                                  size: const Size(20.0, 20.0),
                                  padding: const EdgeInsets.only(right: 5.0),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors.transparent,
                                      builder: (context) =>
                                          MemoryView(characterData: hero),
                                    );
                                  },
                                  tooltip: engine.locale('history'),
                                  icon: const Image(
                                    image: AssetImage(
                                        'assets/images/icon/status.png'),
                                  ),
                                ),
                                Tooltip(
                                  message: '${engine.locale('money')}: $money',
                                  child: Row(
                                    children: [
                                      const Image(
                                          width: 20,
                                          height: 20,
                                          image: AssetImage(
                                              'assets/images/item/money.png')),
                                      Container(
                                        width: 60.0,
                                        padding:
                                            const EdgeInsets.only(right: 5.0),
                                        child: Text(
                                          money,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message:
                                      '${engine.locale('spiritStone')}: $spiritStone',
                                  child: Row(
                                    children: [
                                      const Image(
                                          width: 20,
                                          height: 20,
                                          image: AssetImage(
                                              'assets/images/item/spirit_stone.png')),
                                      Container(
                                        width: 60.0,
                                        padding:
                                            const EdgeInsets.only(right: 5.0),
                                        child: Text(
                                          spiritStone,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ),
          ],
        ),
      ],
    );
  }
}
