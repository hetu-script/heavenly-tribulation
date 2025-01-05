import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/view/character/details.dart';
// import 'package:hetu_script/values.dart';
import 'package:samsara/ui/bordered_icon_button.dart';
import 'package:samsara/ui/dynamic_color_progressbar.dart';
// import 'package:samsara/tilemap.dart';
import 'package:provider/provider.dart';

import '../view/avatar.dart';
import '../view/character/profile.dart';
import '../view/character/memory.dart';
import '../engine.dart';
// import '../view/character/details.dart';
import '../state/selected_tile.dart';
import '../state/hero.dart';
import '../view/character/quest.dart';
import '../ui.dart';
import '../state/windows.dart';

const tickName = {
  1: 'morning.jpg',
  2: 'afternoon.jpg',
  3: 'evening.jpg',
  4: 'night.jpg',
};

class HeroInfoPanel extends StatefulWidget {
  const HeroInfoPanel({super.key});

  @override
  State<HeroInfoPanel> createState() => _HeroInfoPanelState();
}

class _HeroInfoPanelState extends State<HeroInfoPanel> {
  // List<Widget> _buildMaterials() {
  //   final data = _characterData['materials'];
  //   final List<Widget> materials = [];
  //   materials.add(_buildMaterial('money', data, ignoreZero: true)!);
  //   materials.add(_buildMaterial('jade', data, ignoreZero: true)!);
  //   for (final name in kMaterials) {
  //     final widget = _buildMaterial(name, data);
  //     if (widget != null) {
  //       materials.add(widget);
  //     }
  //   }
  //   return materials;
  // }

  // Widget? _buildMaterial(String name, dynamic data, {bool ignoreZero = false}) {
  //   final value = data[name];
  //   if (value > 0 || ignoreZero) {
  //     return Tooltip(
  //       message: engine.locale('$name.description'),
  //       child: Container(
  //         width: 100.0,
  //         padding: const EdgeInsets.only(right: 5.0),
  //         child: Row(
  //           children: [
  //             Text('${engine.locale(name)}:'),
  //             Expanded(
  //               child: Text(
  //                 '$value',
  //                 textAlign: TextAlign.end,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  //   return null;
  // }

  late Offset _dragStartPosition;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final heroData = context.watch<HeroState>().heroData;
    if (heroData == null) {
      return Container();
    }

    final visibleWindows = context.watch<WindowPriorityState>().visibleWindows;

    final currentZone = context.watch<SelectedTileState>().currentZone;
    final currentNation = context.watch<SelectedTileState>().currentNation;
    final currentLocation = context.watch<SelectedTileState>().currentLocation;
    final currentTerrain = context.watch<SelectedTileState>().currentTerrain;

    final dateString = engine.hetu.invoke('getCurrentDateTimeString');
    // final tick = engine.hetu.fetch('ticksOfDay');

    final money = (heroData?['materials']['money']).toString();
    final jade = (heroData?['materials']['jade']).toString();

    final locationDetails = StringBuffer();

    if (currentTerrain?.isLighted ?? false) {
      if (currentZone != null) {
        locationDetails.write('${currentZone!['name']}, ');
      }
      if (currentNation != null) {
        locationDetails.write('${currentNation['name']}, ');
      }
      if (currentLocation != null) {
        locationDetails.write('${currentLocation['name']}, ');
      }
      if (currentTerrain?.kind != null) {
        locationDetails.write('${engine.locale(currentTerrain!.kind)}, ');
      }
    }

    if (currentTerrain != null) {
      locationDetails.write('${currentTerrain.left}, ${currentTerrain.top}');
    }

    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(
                color: GameUI.backgroundColor,
                size: const Size(120, 120),
                image: AssetImage(
                    'assets/images/illustration/${heroData['icon']}'),
              ),
              Container(
                width: 420,
                height: 75,
                decoration: BoxDecoration(
                  color: GameUI.backgroundColor,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: GameUI.foregroundColor),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DynamicColorProgressBar(
                              title: '${engine.locale('stamina')}:',
                              value: heroData['stats']['stamina'],
                              max: heroData['stats']['staminaMax'],
                              height: 16.0,
                              width: 135.0,
                              showNumber: false,
                              showNumberAsPercentage: false,
                              colors: <Color>[
                                Colors.yellow.shade400,
                                Colors.yellow.shade900,
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              BorderedIconButton(
                                size: GameUI.infoButtonSize,
                                padding: const EdgeInsets.only(right: 5.0),
                                onPressed: () {
                                  context
                                      .read<WindowPriorityState>()
                                      .toogleWindow('profile');
                                },
                                tooltip: engine.locale('information'),
                                icon: const Image(
                                  image: AssetImage(
                                      'assets/images/icon/information.png'),
                                ),
                              ),
                              BorderedIconButton(
                                size: GameUI.infoButtonSize,
                                padding: const EdgeInsets.only(right: 5.0),
                                onPressed: () {
                                  context
                                      .read<WindowPriorityState>()
                                      .toogleWindow('details');
                                },
                                tooltip: engine.locale('build'),
                                icon: const Image(
                                  image: AssetImage(
                                      'assets/images/icon/inventory.png'),
                                ),
                              ),
                              BorderedIconButton(
                                size: GameUI.infoButtonSize,
                                padding: const EdgeInsets.only(right: 5.0),
                                onPressed: () {
                                  context
                                      .read<WindowPriorityState>()
                                      .toogleWindow('memory');
                                },
                                tooltip: engine.locale('history'),
                                icon: const Image(
                                  image: AssetImage(
                                      'assets/images/icon/memory.png'),
                                ),
                              ),
                              BorderedIconButton(
                                size: GameUI.infoButtonSize,
                                padding: const EdgeInsets.only(right: 5.0),
                                onPressed: () {
                                  context
                                      .read<WindowPriorityState>()
                                      .toogleWindow('quest');
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
                      padding: const EdgeInsets.only(top: 5.0, right: 5.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateString),
                          Text(locationDetails.toString()),
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
          for (final windowId in visibleWindows)
            switch (windowId) {
              'profile' => CharacterProfileView(
                  characterData: heroData,
                  showIntimacy: false,
                  showRelationships: false,
                  showPosition: false,
                  showPersonality: false,
                  showDescription: true,
                  onClose: () {
                    context.read<WindowPriorityState>().toogleWindow('profile');
                  },
                  onDragUpdate: (details) {
                    context.read<WindowPositionState>().updatePosition(
                          'profile',
                          details.globalPosition - _dragStartPosition,
                        );
                  },
                  onTapDown: (position) {
                    context.read<WindowPriorityState>().setUpFront('profile');
                    _dragStartPosition = position;
                  },
                ),
              'details' => CharacterDetailsView(
                  characterData: heroData,
                  onClose: () {
                    context.read<WindowPriorityState>().toogleWindow('details');
                  },
                  onDragUpdate: (details) {
                    context.read<WindowPositionState>().updatePosition(
                          'details',
                          details.globalPosition - _dragStartPosition,
                        );
                  },
                  onTapDown: (position) {
                    context.read<WindowPriorityState>().setUpFront('details');
                    _dragStartPosition = position;
                  },
                ),
              'memory' => CharacterMemoryView(
                  characterData: heroData,
                  isHero: true,
                  onClose: () {
                    context.read<WindowPriorityState>().toogleWindow('memory');
                  },
                  onDragUpdate: (details) {
                    context.read<WindowPositionState>().updatePosition(
                          'memory',
                          details.globalPosition - _dragStartPosition,
                        );
                  },
                  onTapDown: (position) {
                    context.read<WindowPriorityState>().setUpFront('memory');
                    _dragStartPosition = position;
                  },
                ),
              'quest' => CharacterQuestView(
                  characterData: heroData,
                  onClose: () {
                    context.read<WindowPriorityState>().toogleWindow('quest');
                  },
                  onDragUpdate: (details) {
                    context.read<WindowPositionState>().updatePosition(
                          'quest',
                          details.globalPosition - _dragStartPosition,
                        );
                  },
                  onTapDown: (position) {
                    context.read<WindowPriorityState>().setUpFront('quest');
                    _dragStartPosition = position;
                  },
                ),
              _ => Container(),
            }
        ],
      ),
    );
  }
}
