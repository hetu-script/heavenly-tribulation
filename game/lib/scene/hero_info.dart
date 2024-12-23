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
import '../view/character/equipments_and_stats.dart';
import '../state/selected_tile.dart';
import '../state/hero.dart';
import '../view/quest.dart';

const tickName = {
  1: 'morning.jpg',
  2: 'afternoon.jpg',
  3: 'evening.jpg',
  4: 'night.jpg',
};

class HeroInfoPanel extends StatelessWidget {
  const HeroInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final heroData = context.watch<HeroState>().heroData;
    final currentZone = context.watch<SelectedTileState>().currentZone;
    final currentNation = context.watch<SelectedTileState>().currentNation;
    final currentLocation = context.watch<SelectedTileState>().currentLocation;
    final currentTerrain = context.watch<SelectedTileState>().currentTerrain;

    final dateString = engine.hetu.invoke('getCurrentDateTimeString');
    // final tick = engine.hetu.fetch('ticksOfDay');

    final money = (heroData?['materials']['money']).toString();
    final jade = (heroData?['materials']['jade']).toString();

    final sb2 = StringBuffer();

    if (currentTerrain?.isLighted ?? false) {
      if (currentZone != null) {
        sb2.write('${currentZone!['name']}, ');
      }
      if (currentNation != null) {
        sb2.write('${currentNation['name']}, ');
      }
      if (currentLocation != null) {
        sb2.write('${currentLocation['name']}, ');
      }
      if (currentTerrain?.kind != null) {
        sb2.write('${engine.locale(currentTerrain!.kind)}, ');
      }
    }

    if (currentTerrain != null) {
      sb2.write('${currentTerrain.left}, ${currentTerrain.top}');
    }

    return heroData != null
        ? Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(
                    color: kBackgroundColor,
                    size: const Size(120, 120),
                    image: AssetImage(
                        'assets/images/illustration/${heroData['icon']}'),
                  ),
                  Container(
                    width: 420,
                    height: 80,
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: kForegroundColor),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 5),
                              //   child: DynamicColorProgressBar(
                              //     title: '${engine.locale('life')}:',
                              //     value: heroData['stats']['life'],
                              //     max: heroData['stats']['lifeMax'],
                              //     height: 16.0,
                              //     width: 155.0,
                              //     showNumber: false,
                              //     showNumberAsPercentage: false,
                              //     colors: <Color>[
                              //       Colors.red.shade400,
                              //       Colors.red.shade900
                              //     ],
                              //   ),
                              // ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: DynamicColorProgressBar(
                                  title: '${engine.locale('stamina')}:',
                                  value: heroData['stats']['stamina'],
                                  max: heroData['stats']['staminaMax'],
                                  height: 16.0,
                                  width: 155.0,
                                  showNumber: false,
                                  showNumberAsPercentage: false,
                                  colors: <Color>[
                                    Colors.yellow.shade400,
                                    Colors.yellow.shade900,
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: DynamicColorProgressBar(
                                  title: '${engine.locale('mana')}:',
                                  value: heroData['stats']['mana'],
                                  max: heroData['stats']['manaMax'],
                                  height: 16.0,
                                  width: 155.0,
                                  showNumber: false,
                                  showNumberAsPercentage: false,
                                  colors: <Color>[
                                    Colors.purple.shade400,
                                    Colors.purple.shade900,
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  BorderedIconButton(
                                    size: const Size(20.0, 20.0),
                                    padding: const EdgeInsets.only(right: 5.0),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        barrierColor: Colors.transparent,
                                        builder: (context) => ProfileView(
                                          characterData: heroData,
                                          showIntimacy: false,
                                          showRelationships: false,
                                          showPosition: false,
                                          showPersonality: false,
                                          showDescription: true,
                                        ),
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
                                            EquipmentsAndStatsView(
                                                characterData: heroData),
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
                                        builder: (context) => MemoryView(
                                          characterData: heroData,
                                          isHero: true,
                                        ),
                                      );
                                    },
                                    tooltip: engine.locale('history'),
                                    icon: const Image(
                                      image: AssetImage(
                                          'assets/images/icon/memory.png'),
                                    ),
                                  ),
                                  BorderedIconButton(
                                    size: const Size(20.0, 20.0),
                                    padding: const EdgeInsets.only(right: 5.0),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        barrierColor: Colors.transparent,
                                        builder: (context) => QuestView(
                                          characterData: heroData,
                                        ),
                                      );
                                    },
                                    tooltip: engine.locale('quest'),
                                    icon: const Image(
                                      image: AssetImage(
                                          'assets/images/icon/quest.png'),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateString),
                              Text(sb2.toString()),
                              Row(
                                children: [
                                  Tooltip(
                                    message: engine.locale('money.description'),
                                    child: Row(
                                      children: [
                                        const Image(
                                            width: 20,
                                            height: 20,
                                            image: AssetImage(
                                                'assets/images/item/material/money.png')),
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
                                    message: engine.locale('jade.description'),
                                    child: Row(
                                      children: [
                                        const Image(
                                            width: 20,
                                            height: 20,
                                            image: AssetImage(
                                                'assets/images/item/material/jade.png')),
                                        Container(
                                          width: 60.0,
                                          padding:
                                              const EdgeInsets.only(right: 5.0),
                                          child: Text(
                                            jade,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
        : Container();
  }
}
