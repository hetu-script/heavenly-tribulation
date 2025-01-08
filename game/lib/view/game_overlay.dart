import 'package:flutter/material.dart';
// import 'package:hetu_script/values.dart';
import 'package:samsara/ui/bordered_icon_button.dart';
import 'package:samsara/ui/dynamic_color_progressbar.dart';
// import 'package:samsara/tilemap.dart';
import 'package:provider/provider.dart';
// import 'package:samsara/richtext.dart';
import 'package:samsara/ui/mouse_region2.dart';

import 'avatar.dart';
import 'character/profile.dart';
import 'character/memory.dart';
import '../engine.dart';
// import '../view/character/details.dart';
import '../state/selected_tile.dart';
import '../state/hero.dart';
import 'character/quest.dart';
import '../ui.dart';
import '../state/windows.dart';
import 'hoverinfo.dart';
import '../state/hover_info.dart';
import '../scene/card_library/card_library.dart';
// import '../data.dart';
import '../scene/common.dart';
import 'character/details.dart';
import '../scene/battle/prebattle.dart';

const tickName = {
  1: 'morning.jpg',
  2: 'afternoon.jpg',
  3: 'evening.jpg',
  4: 'night.jpg',
};

class GameOverlay extends StatefulWidget {
  final String sceneId;

  const GameOverlay({
    required this.sceneId,
    super.key,
  });

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay> {
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

  // dynamic hoveringItemData;
  // Rect? hoveringItemRect;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final isVisible = context.watch<GameOverlayVisibilityState>().isVisible;

    final heroData = context.watch<HeroState>().heroData;

    if (!isVisible || heroData == null) {
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

    final (info, rect) = context.watch<HoverInfoContentState>().get();

    final enemyData = context.watch<EnemyState>().enemyData;
    final showPrebattle = context.watch<EnemyState>().showPrebattle;

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
                width: 460,
                height: 85,
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
                              value: heroData['stats']['life'],
                              max: heroData['stats']['lifeMax'],
                              height: 25.0,
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
                                onTap: () {
                                  context
                                      .read<WindowPriorityState>()
                                      .toogle('profile');
                                },
                                onMouseEnter: (rect) {
                                  context
                                      .read<HoverInfoContentState>()
                                      .set(engine.locale('information'), rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                icon: const Image(
                                  image: AssetImage(
                                      'assets/images/icon/information.png'),
                                ),
                              ),
                              BorderedIconButton(
                                size: GameUI.infoButtonSize,
                                padding: const EdgeInsets.only(right: 5.0),
                                onTap: () {
                                  context
                                      .read<WindowPriorityState>()
                                      .toogle('details');
                                },
                                onMouseEnter: (rect) {
                                  context
                                      .read<HoverInfoContentState>()
                                      .set(engine.locale('build'), rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                icon: const Image(
                                  image: AssetImage(
                                      'assets/images/icon/inventory.png'),
                                ),
                              ),
                              BorderedIconButton(
                                size: GameUI.infoButtonSize,
                                padding: const EdgeInsets.only(right: 5.0),
                                onTap: () {
                                  context
                                      .read<WindowPriorityState>()
                                      .toogle('memory');
                                },
                                onMouseEnter: (rect) {
                                  context
                                      .read<HoverInfoContentState>()
                                      .set(engine.locale('history'), rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                icon: const Image(
                                  image: AssetImage(
                                      'assets/images/icon/memory.png'),
                                ),
                              ),
                              BorderedIconButton(
                                size: GameUI.infoButtonSize,
                                padding: const EdgeInsets.only(right: 5.0),
                                onTap: () {
                                  context
                                      .read<WindowPriorityState>()
                                      .toogle('quest');
                                },
                                onMouseEnter: (rect) {
                                  context
                                      .read<HoverInfoContentState>()
                                      .set(engine.locale('quest'), rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                icon: const Image(
                                  image: AssetImage(
                                      'assets/images/icon/quest.png'),
                                ),
                              ),
                              if (widget.sceneId != kSceneCardLibrary)
                                BorderedIconButton(
                                  size: GameUI.infoButtonSize,
                                  padding: const EdgeInsets.only(right: 5.0),
                                  onTap: () {
                                    context
                                        .read<WindowPriorityState>()
                                        .clearAll();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        requestFocus: true,
                                        builder: (context) =>
                                            CardLibraryOverlay(),
                                      ),
                                    );
                                  },
                                  onMouseEnter: (rect) {
                                    context.read<HoverInfoContentState>().set(
                                        engine.locale('card_library'), rect);
                                  },
                                  onMouseExit: () {
                                    context
                                        .read<HoverInfoContentState>()
                                        .hide();
                                  },
                                  icon: const Image(
                                    image: AssetImage(
                                        'assets/images/icon/library.png'),
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
                              MouseRegion2(
                                onMouseEnter: (rect) {
                                  context.read<HoverInfoContentState>().set(
                                      engine.locale('money_description'), rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                child: Row(
                                  children: [
                                    const Image(
                                        width: 20,
                                        height: 20,
                                        image: AssetImage(
                                            'assets/images/item/material/money.png')),
                                    Container(
                                      width: 80.0,
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
                              MouseRegion2(
                                onMouseEnter: (rect) {
                                  context.read<HoverInfoContentState>().set(
                                      engine.locale('jade_description'), rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                child: Row(
                                  children: [
                                    const Image(
                                        width: 20,
                                        height: 20,
                                        image: AssetImage(
                                            'assets/images/item/material/jade.png')),
                                    Container(
                                      width: 80.0,
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
                              MouseRegion2(
                                onMouseEnter: (rect) {
                                  StringBuffer materials = StringBuffer();
                                  final data = heroData!['materials'];
                                  materials.writeln(
                                      '${engine.locale('food')}: ${(data['food'] as int).toString().padLeft(10)}');
                                  materials.writeln(
                                      '${engine.locale('water')}: ${(data['water'] as int).toString().padLeft(10)}');
                                  materials.writeln(
                                      '${engine.locale('stone')}: ${(data['stone'] as int).toString().padLeft(10)}');
                                  materials.writeln(
                                      '${engine.locale('ore')}: ${(data['ore'] as int).toString().padLeft(10)}');
                                  materials.writeln(
                                      '${engine.locale('plank')}: ${(data['plank'] as int).toString().padLeft(10)}');
                                  materials.writeln(
                                      '${engine.locale('paper')}: ${(data['paper'] as int).toString().padLeft(10)}');
                                  materials.write(
                                      '${engine.locale('herb')}: ${(data['herb'] as int).toString().padLeft(10)}');
                                  final content = materials.toString();

                                  context
                                      .read<HoverInfoContentState>()
                                      .set(content, rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                child: Row(
                                  children: [
                                    const Image(
                                        width: 20,
                                        height: 20,
                                        image: AssetImage(
                                            'assets/images/item/material.png')),
                                    Container(
                                      width: 40.0,
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Text(
                                        engine.locale('material'),
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
          if (enemyData != null && showPrebattle)
            Positioned.fill(
              child: PreBattleDialog(heroData: heroData, enemyData: enemyData),
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
                    context.read<WindowPriorityState>().hide('profile');
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
                    context.read<WindowPriorityState>().hide('details');
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
                    context.read<WindowPriorityState>().hide('memory');
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
                    context.read<WindowPriorityState>().hide('quest');
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
            },
          if (info != null && rect != null)
            HoverInfo(content: info, hoveringRect: rect),
        ],
      ),
    );
  }
}
