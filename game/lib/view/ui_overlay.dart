import 'package:flutter/material.dart';
import 'package:samsara/ui/bordered_icon_button.dart';
import 'package:samsara/ui/dynamic_color_progressbar.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/mouse_region2.dart';
import 'package:samsara/samsara.dart';

import 'avatar.dart';
import 'character/profile.dart';
import 'character/memory.dart';
import '../engine.dart';
import 'character/quest.dart';
import '../ui.dart';
import 'hoverinfo.dart';
import 'character/details.dart';
import 'prebatle/prebattle.dart';
import '../state/states.dart';
import '../scene/common.dart';
import '../view/dialog/item_select_dialog.dart';

const tickName = {
  1: 'morning.jpg',
  2: 'afternoon.jpg',
  3: 'evening.jpg',
  4: 'night.jpg',
};

class GameUIOverlay extends StatefulWidget {
  const GameUIOverlay({
    super.key,
    this.showLibrary = true,
  });

  final bool showLibrary;

  @override
  State<GameUIOverlay> createState() => _GameUIOverlayState();
}

class _GameUIOverlayState extends State<GameUIOverlay> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final isVisible = context.watch<GameUIOverlayVisibilityState>().isVisible;

    final heroData = context.watch<HeroState>().heroData;

    if (!isVisible || heroData == null) {
      return Container();
    }

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

    final (data, rect, direction) =
        context.watch<HoverInfoContentState>().get();

    final enemyData = context.watch<EnemyState>().enemyData;
    final showPrebattle = context.watch<EnemyState>().showPrebattle;

    final visiblePanels = context.watch<ViewPanelState>().visiblePanels;
    final List<Widget> panels = [];
    for (final panel in visiblePanels.keys) {
      switch (panel) {
        case ViewPanels.characterProfile:
          panels.add(CharacterProfileView(
            characterData: heroData,
            showIntimacy: false,
            showRelationships: false,
            showPosition: false,
            showPersonality: false,
            showDescription: true,
          ));
        case ViewPanels.characterMemory:
          panels.add(CharacterMemoryView(
            characterData: heroData,
            isHero: true,
          ));
        case ViewPanels.characterQuest:
          panels.add(CharacterQuestView(
            characterData: heroData,
          ));
        case ViewPanels.characterDetails:
          panels.add(CharacterDetailsView(
            characterData: heroData,
          ));
        case ViewPanels.itemSelect:
          final arguments = visiblePanels[panel]!;
          panels.add(ItemSelectDialog(
            inventoryData: arguments['inventoryData'],
            title: arguments['title'],
            filter: arguments['filter'],
            onSelect: arguments['onSelect'],
            onSelectAll: arguments['onSelectAll'],
          ));
      }
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  width: 170.0,
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
                                    onTapUp: () {
                                      context
                                          .read<ViewPanelState>()
                                          .toogle(ViewPanels.characterProfile);
                                    },
                                    onMouseEnter: (rect) {
                                      context.read<HoverInfoContentState>().set(
                                          engine.locale('information'), rect);
                                    },
                                    onMouseExit: () {
                                      context
                                          .read<HoverInfoContentState>()
                                          .hide();
                                    },
                                    child: const Image(
                                      image: AssetImage(
                                          'assets/images/icon/information.png'),
                                    ),
                                  ),
                                  BorderedIconButton(
                                    size: GameUI.infoButtonSize,
                                    padding: const EdgeInsets.only(right: 5.0),
                                    onTapUp: () {
                                      context
                                          .read<ViewPanelState>()
                                          .toogle(ViewPanels.characterMemory);
                                    },
                                    onMouseEnter: (rect) {
                                      context
                                          .read<HoverInfoContentState>()
                                          .set(engine.locale('history'), rect);
                                    },
                                    onMouseExit: () {
                                      context
                                          .read<HoverInfoContentState>()
                                          .hide();
                                    },
                                    child: const Image(
                                      image: AssetImage(
                                          'assets/images/icon/memory.png'),
                                    ),
                                  ),
                                  BorderedIconButton(
                                    size: GameUI.infoButtonSize,
                                    padding: const EdgeInsets.only(right: 5.0),
                                    onTapUp: () {
                                      context
                                          .read<ViewPanelState>()
                                          .toogle(ViewPanels.characterQuest);
                                    },
                                    onMouseEnter: (rect) {
                                      context
                                          .read<HoverInfoContentState>()
                                          .set(engine.locale('quest'), rect);
                                    },
                                    onMouseExit: () {
                                      context
                                          .read<HoverInfoContentState>()
                                          .hide();
                                    },
                                    child: const Image(
                                      image: AssetImage(
                                          'assets/images/icon/quest.png'),
                                    ),
                                  ),
                                  BorderedIconButton(
                                    size: GameUI.infoButtonSize,
                                    padding: const EdgeInsets.only(right: 5.0),
                                    onTapUp: () {
                                      context
                                          .read<ViewPanelState>()
                                          .toogle(ViewPanels.characterDetails);
                                    },
                                    onMouseEnter: (rect) {
                                      context
                                          .read<HoverInfoContentState>()
                                          .set(engine.locale('build'), rect);
                                    },
                                    onMouseExit: () {
                                      context
                                          .read<HoverInfoContentState>()
                                          .hide();
                                    },
                                    child: const Image(
                                      image: AssetImage(
                                          'assets/images/icon/inventory.png'),
                                    ),
                                  ),
                                  if (widget.showLibrary)
                                    BorderedIconButton(
                                      size: GameUI.infoButtonSize,
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      onTapUp: () {
                                        context
                                            .read<HoverInfoContentState>()
                                            .hide();
                                        context
                                            .read<ViewPanelState>()
                                            .clearAll();
                                        context
                                            .read<SceneControllerState>()
                                            .push(Scenes.library);
                                      },
                                      onMouseEnter: (rect) {
                                        context
                                            .read<HoverInfoContentState>()
                                            .set(engine.locale('card_library'),
                                                rect);
                                      },
                                      onMouseExit: () {
                                        context
                                            .read<HoverInfoContentState>()
                                            .hide();
                                      },
                                      child: const Image(
                                        image: AssetImage(
                                            'assets/images/icon/library.png'),
                                      ),
                                    ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const Spacer(),
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
                                          engine.locale('money_description'),
                                          rect);
                                    },
                                    onMouseExit: () {
                                      context
                                          .read<HoverInfoContentState>()
                                          .hide();
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
                                          engine.locale('jade_description'),
                                          rect);
                                    },
                                    onMouseExit: () {
                                      context
                                          .read<HoverInfoContentState>()
                                          .hide();
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
                                      context
                                          .read<HoverInfoContentState>()
                                          .hide();
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
                  Row(
                    children: [
                      BorderedIconButton(
                        size: GameUI.infoButtonSize,
                        padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                        onTapUp: () {
                          context.read<HoverInfoContentState>().hide();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => Console(
                              engine: engine,
                              margin: const EdgeInsets.all(50.0),
                              backgroundColor: GameUI.backgroundColor,
                            ),
                          );
                        },
                        onMouseEnter: (rect) {
                          context
                              .read<HoverInfoContentState>()
                              .set(engine.locale('console'), rect);
                        },
                        onMouseExit: () {
                          context.read<HoverInfoContentState>().hide();
                        },
                        child: const Image(
                          image: AssetImage('assets/images/icon/status.png'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (enemyData != null && showPrebattle)
            Positioned.fill(
              child: PreBattleDialog(heroData: heroData, enemyData: enemyData),
            ),
          ...panels,
          if (data != null && rect != null)
            HoverInfo(data: data, hoveringRect: rect, direction: direction),
        ],
      ),
    );
  }
}
