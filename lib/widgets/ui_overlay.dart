import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/widgets/dialog/new_rank.dart';
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
import '../game/ui.dart';
import 'hoverinfo.dart';
import 'character/details.dart';
import 'prebatle/prebattle.dart';
import '../state/states.dart';
import '../scene/common.dart';
import 'character/item_select_dialog.dart';
import 'draggable_panel.dart';
import '../scene/game_dialog/game_dialog_controller.dart';
import 'history_list.dart';
import 'npc_list.dart';
import 'character/merchant.dart';
import 'dialog/new_items.dart';
import 'dialog/new_quest.dart';
import '../game/data.dart';
import 'character/inventory/equipment_bar.dart';

const tickName = {
  1: 'morning.jpg',
  2: 'afternoon.jpg',
  3: 'evening.jpg',
  4: 'night.jpg',
};

class GameUIOverlay extends StatefulWidget {
  const GameUIOverlay({
    super.key,
    this.enableHeroInfo = true,
    this.enableNpcs = true,
    this.enableLibrary = true,
    this.enableCultivation = true,
    this.enableAutoExhaust = true,
    this.dropMenu,
  });

  final bool enableHeroInfo;
  final bool enableNpcs;
  final bool enableLibrary;
  final bool enableCultivation;
  final bool enableAutoExhaust;
  final Widget? dropMenu;

  @override
  State<GameUIOverlay> createState() => _GameUIOverlayState();
}

class _GameUIOverlayState extends State<GameUIOverlay> {
  final Set<String> _prompts = {};

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    final bool autoCultivate = widget.enableAutoExhaust &&
        (GameData.gameData['flags']['autoCultivate'] ?? false);
    final bool autoWork = widget.enableAutoExhaust &&
        (GameData.gameData['flags']['autoWork'] ?? false);

    final heroData = context.watch<HeroState>().heroData;
    final showHeroInfo = widget.enableHeroInfo &&
        heroData != null &&
        context.watch<HeroInfoVisibilityState>().isVisible;

    final currentZone = context.watch<SelectedTileState>().currentZone;
    final currentNation = context.watch<SelectedTileState>().currentNation;
    final currentLocation = context.watch<SelectedTileState>().currentLocation;
    final currentTerrain = context.watch<SelectedTileState>().currentTerrain;

    final dateString = context.watch<GameTimestampState>().gameDateTimeString;

    final money = (heroData?['materials']['money']).toString();
    final shard = (heroData?['materials']['shard']).toString();

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

    final content = context.watch<HoverInfoContentState>().content;

    final enemyData = context.watch<EnemyState>().enemyData;
    final showPrebattle = context.watch<EnemyState>().showPrebattle;

    final merchantData = context.watch<MerchantState>().merchantData;
    final priceFactor = context.watch<MerchantState>().priceFactor;
    final showMerchant = context.watch<MerchantState>().showMerchant;

    final newQuest = context.watch<NewQuestState>().quest;
    final newItems = context.watch<NewItemsState>().items;
    final newItemsCompleter = context.watch<NewItemsState>().completer;
    final newRank = context.watch<NewRankState>().rank;

    if (newRank != null) {
      _prompts.add('rank');
    } else {
      _prompts.remove('rank');
    }
    if (newItems != null) {
      _prompts.add('item');
    } else {
      _prompts.remove('item');
    }
    if (newQuest != null) {
      _prompts.add('quest');
    } else {
      _prompts.remove('quest');
    }

    final visiblePanels = context.watch<ViewPanelState>().visiblePanels;
    final panelPositions =
        context.watch<ViewPanelPositionState>().panelPositions;
    final List<Widget> panels = [];
    for (final panel in visiblePanels.keys) {
      // final arguments = visiblePanels[panel];
      switch (panel) {
        case ViewPanels.characterProfile:
          final position =
              panelPositions[panel] ?? GameUI.profileWindowPosition;
          panels.add(
            DraggablePanel(
              title: engine.locale('information'),
              position: position,
              width: GameUI.profileWindowSize.x,
              height: GameUI.profileWindowSize.y,
              onTapDown: (offset) {
                context
                    .read<ViewPanelState>()
                    .setUpFront(ViewPanels.characterProfile);
                context
                    .read<ViewPanelPositionState>()
                    .set(ViewPanels.characterProfile, position);
              },
              onDragUpdate: (details) {
                context
                    .read<ViewPanelPositionState>()
                    .update(ViewPanels.characterProfile, details.delta);
              },
              onClose: () {
                context
                    .read<ViewPanelState>()
                    .hide(ViewPanels.characterProfile);
              },
              child: CharacterProfile(
                height: 340.0,
                characterData: heroData,
                showIntimacy: false,
                showRelationships: false,
                showPosition: false,
                showPersonality: false,
                showDescription: true,
              ),
            ),
          );
        case ViewPanels.characterDetails:
          final position =
              panelPositions[panel] ?? GameUI.detailsWindowPosition;
          panels.add(
            DraggablePanel(
              title: engine.locale('stats_and_inventory'),
              position: position,
              width: GameUI.profileWindowSize.x,
              height: GameUI.profileWindowSize.y,
              onTapDown: (offset) {
                context
                    .read<ViewPanelState>()
                    .setUpFront(ViewPanels.characterDetails);
                context
                    .read<ViewPanelPositionState>()
                    .set(ViewPanels.characterDetails, position);
              },
              onDragUpdate: (details) {
                context
                    .read<ViewPanelPositionState>()
                    .update(ViewPanels.characterDetails, details.delta);
              },
              onClose: () {
                context
                    .read<ViewPanelState>()
                    .hide(ViewPanels.characterDetails);
              },
              child: CharacterDetails(characterData: heroData),
            ),
          );
        case ViewPanels.characterMemory:
          final position = context
                  .watch<ViewPanelPositionState>()
                  .get(ViewPanels.characterMemory) ??
              GameUI.profileWindowPosition;
          panels.add(
            DraggablePanel(
              title: engine.locale('memory'),
              position: position,
              width: GameUI.profileWindowSize.x,
              height: GameUI.profileWindowSize.y,
              // titleHeight: 100,
              onTapDown: (offset) {
                context
                    .read<ViewPanelState>()
                    .setUpFront(ViewPanels.characterMemory);
                context
                    .read<ViewPanelPositionState>()
                    .set(ViewPanels.characterMemory, position);
              },
              onDragUpdate: (details) {
                context.read<ViewPanelPositionState>().update(
                      ViewPanels.characterMemory,
                      details.delta,
                    );
              },
              onClose: () {
                context.read<ViewPanelState>().hide(ViewPanels.characterMemory);
              },
              child: CharacterMemory(characterData: heroData, isHero: true),
            ),
          );
        case ViewPanels.itemSelect:
          final arguments = visiblePanels[panel]!;
          panels.add(ItemSelectDialog(
            characterData: arguments['characterData'],
            title: arguments['title'],
            filter: arguments['filter'],
            multiSelect: arguments['multiSelect'] ?? false,
            onSelect: arguments['onSelect'],
          ));
        case ViewPanels.characterQuest:
          panels.add(QuestView(characterData: heroData));
      }
    }

    final life = heroData?['stats']['life'];
    final lifeMax = heroData?['stats']['lifeMax'];

    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: Stack(
        children: [
          if (showHeroInfo)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(
                  borderRadius: 0.0,
                  cursor: SystemMouseCursors.click,
                  color: GameUI.backgroundColor2,
                  size: const Size(150, 150),
                  image: AssetImage('assets/images/${heroData['icon']}'),
                  onPressed: (_) {},
                ),
                Container(
                  width: 250,
                  height: 150,
                  decoration: BoxDecoration(
                    color: GameUI.backgroundColor2,
                    // borderRadius: BorderRadius.circular(10.0),
                    // border: Border.all(color: GameUI.foregroundColor),
                  ),
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.only(bottom: 10.0, left: 10.0),
                        child: DynamicColorProgressBar(
                          value: life,
                          max: lifeMax,
                          height: 25.0,
                          width: 230.0,
                          showNumber: false,
                          showNumberAsPercentage: false,
                          colors: <Color>[
                            Colors.yellow.shade400,
                            Colors.yellow.shade900,
                          ],
                          onMouseEnter: (rect) {
                            final content =
                                '${engine.locale('stamina')}: $life/$lifeMax';
                            context
                                .read<HoverInfoContentState>()
                                .show(content, rect);
                          },
                          onMouseExit: () {
                            context.read<HoverInfoContentState>().hide();
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Row(
                          children: [
                            BorderedIconButton(
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.only(right: 10),
                              onTapUp: () {
                                context
                                    .read<ViewPanelState>()
                                    .toogle(ViewPanels.characterProfile);
                              },
                              onMouseEnter: (rect) {
                                context
                                    .read<HoverInfoContentState>()
                                    .show(engine.locale('information'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverInfoContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/information.png'),
                              ),
                            ),
                            BorderedIconButton(
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.only(right: 10),
                              onTapUp: () {
                                context
                                    .read<ViewPanelState>()
                                    .toogle(ViewPanels.characterQuest);
                              },
                              onMouseEnter: (rect) {
                                context
                                    .read<HoverInfoContentState>()
                                    .show(engine.locale('quest'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverInfoContentState>().hide();
                              },
                              child: const Image(
                                image:
                                    AssetImage('assets/images/icon/quest.png'),
                              ),
                            ),
                            BorderedIconButton(
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.only(right: 10),
                              onTapUp: () {
                                context
                                    .read<ViewPanelState>()
                                    .toogle(ViewPanels.characterDetails);
                              },
                              onMouseEnter: (rect) {
                                context.read<HoverInfoContentState>().show(
                                    engine.locale('stats_and_inventory'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverInfoContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/inventory.png'),
                              ),
                            ),
                            BorderedIconButton(
                              isEnabled: widget.enableLibrary,
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.only(right: 10),
                              onTapUp: () {
                                engine.pushScene(Scenes.cardlibrary);
                              },
                              onMouseEnter: (rect) {
                                context
                                    .read<HoverInfoContentState>()
                                    .show(engine.locale('card_library'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverInfoContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/library.png'),
                              ),
                            ),
                            BorderedIconButton(
                              isEnabled: widget.enableCultivation,
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.only(right: 10),
                              onTapUp: () {
                                engine.pushScene(Scenes.cultivation);
                              },
                              onMouseEnter: (rect) {
                                context
                                    .read<HoverInfoContentState>()
                                    .show(engine.locale('cultivate'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverInfoContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/cultivate.png'),
                              ),
                            ),
                            Row(
                              children: [
                                BorderedIconButton(
                                  size: GameUI.infoButtonSize,
                                  onTapUp: () {
                                    context
                                        .read<HoverInfoContentState>()
                                        .hide();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          Console(
                                        engine: engine,
                                        margin: const EdgeInsets.all(50.0),
                                        backgroundColor:
                                            GameUI.backgroundColor2,
                                      ),
                                    );
                                  },
                                  onMouseEnter: (rect) {
                                    context
                                        .read<HoverInfoContentState>()
                                        .show(engine.locale('console'), rect);
                                  },
                                  onMouseExit: () {
                                    context
                                        .read<HoverInfoContentState>()
                                        .hide();
                                  },
                                  child: const Image(
                                    image: AssetImage(
                                        'assets/images/icon/unknown_item.png'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: EquipmentBar(
                          type: ItemType.player,
                          characterData: heroData,
                          gridSize: const Size(30.0, 30.0),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          bottom: 5.0,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: MouseRegion2(
                                cursor: SystemMouseCursors.click,
                                onTapUp: () {
                                  context.read<HoverInfoContentState>().hide();
                                  if (widget.enableAutoExhaust) {
                                    GameData.gameData['flags']['autoWork'] =
                                        !autoWork;
                                    setState(() {});
                                  }
                                },
                                onMouseEnter: (rect) {
                                  String description =
                                      engine.locale('money_description');
                                  if (widget.enableAutoExhaust) {
                                    description +=
                                        '\n \n<yellow>${engine.locale('autoWork')}: ${autoWork ? engine.locale('opened') : engine.locale('closed')}</>';
                                  } else {}
                                  context
                                      .read<HoverInfoContentState>()
                                      .show(description, rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: autoWork
                                              ? GameUI.foregroundColor
                                              : Colors.transparent,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Image(
                                          width: 20,
                                          height: 20,
                                          image: AssetImage(
                                              'assets/images/item/material/money.${autoWork ? 'gif' : 'png'}')),
                                    ),
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
                            ),
                            Container(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: MouseRegion2(
                                cursor: SystemMouseCursors.click,
                                onTapUp: () {
                                  context.read<HoverInfoContentState>().hide();
                                  if (widget.enableAutoExhaust) {
                                    GameData.gameData['flags']
                                        ['autoCultivate'] = !autoCultivate;
                                    setState(() {});
                                  }
                                },
                                onMouseEnter: (rect) {
                                  String description =
                                      engine.locale('shard_description');
                                  if (widget.enableAutoExhaust) {
                                    description +=
                                        '\n \n<yellow>${engine.locale('autoCultivate')}: ${autoCultivate ? engine.locale('opened') : engine.locale('closed')}</>';
                                  } else {}
                                  context
                                      .read<HoverInfoContentState>()
                                      .show(description, rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverInfoContentState>().hide();
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: autoCultivate
                                              ? GameUI.foregroundColor
                                              : Colors.transparent,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Image(
                                          width: 20,
                                          height: 20,
                                          image: AssetImage(
                                              'assets/images/item/material/shard.${autoCultivate ? 'gif' : 'png'}')),
                                    ),
                                    Container(
                                      width: 80.0,
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Text(
                                        shard,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: MouseRegion2(
                                onMouseEnter: (rect) {
                                  StringBuffer materials = StringBuffer();
                                  final data = heroData!['materials'];
                                  materials.writeln(
                                      '${engine.locale('worker')}: ${(data['worker'] as int).toString().padLeft(10)}');
                                  materials.writeln(
                                      '${engine.locale('herb')}: ${(data['herb'] as int).toString().padLeft(10)}');
                                  materials.writeln(
                                      '${engine.locale('timber')}: ${(data['timber'] as int).toString().padLeft(10)}');
                                  materials.writeln(
                                      '${engine.locale('stone')}: ${(data['stone'] as int).toString().padLeft(10)}');
                                  materials.write(
                                      '${engine.locale('ore')}: ${(data['ore'] as int).toString().padLeft(10)}');
                                  final content = materials.toString();
                                  context
                                      .read<HoverInfoContentState>()
                                      .show(content, rect);
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
                                    // Container(
                                    //   width: 40.0,
                                    //   padding: const EdgeInsets.only(
                                    //       right: 5.0),
                                    //   child: Text(
                                    //     engine.locale('material'),
                                    //     textAlign: TextAlign.end,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 400,
                  height: 150,
                  decoration: BoxDecoration(
                    color: GameUI.backgroundColor2,
                    // borderRadius: BorderRadius.circular(10.0),
                    // border: Border.all(color: GameUI.foregroundColor),
                  ),
                  padding:
                      const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3.0),
                            child: Text(dateString),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3.0),
                            child: Text(locationDetails.toString()),
                          ),
                        ],
                      ),
                      const Divider(height: 10.0),
                      SizedBox(
                        width: 400,
                        height: 100,
                        child: HeroAndGlobalHistoryList(
                          onTapUp: () {
                            context
                                .read<ViewPanelState>()
                                .toogle(ViewPanels.characterMemory);
                          },
                          onMouseEnter: (rect) {
                            context
                                .read<HoverInfoContentState>()
                                .show(engine.locale('history'), rect);
                          },
                          onMouseExit: () {
                            context.read<HoverInfoContentState>().hide();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (widget.dropMenu != null)
            Positioned(
              right: 10,
              top: 10,
              child: widget.dropMenu!,
            ),
          if (widget.enableNpcs)
            const Positioned(
              left: 10,
              top: 135,
              child: NpcList(),
            ),
          if (enemyData != null && showPrebattle)
            PreBattleDialog(heroData: heroData, enemyData: enemyData),
          if (merchantData != null && showMerchant)
            MerchantDialog(
              merchantData: merchantData,
              priceFactor: priceFactor,
            ),
          GameDialogController(),
          ...panels,
          if (_prompts.isNotEmpty)
            switch (_prompts.last) {
              'rank' => NewRank(rank: newRank!),
              'quest' => NewQuest(questData: newQuest!),
              'item' =>
                NewItems(itemsData: newItems!, completer: newItemsCompleter),
              _ => SizedBox.shrink(),
            },
          if (content != null) HoverInfo(content),
        ],
      ),
    );
  }
}
