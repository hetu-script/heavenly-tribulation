import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/widgets/dialog/new_rank.dart';
import 'package:heavenly_tribulation/widgets/location/functional/alchemy.dart';
import 'package:heavenly_tribulation/widgets/location/functional/workshop.dart';
import 'package:samsara/ui/dynamic_color_progressbar.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/mouse_region2.dart';
import 'package:samsara/samsara.dart';

import 'avatar.dart';
import 'character/profile.dart';
import 'character/memory.dart';
import '../engine.dart';
import 'character/journal.dart';
import '../game/ui.dart';
import 'hover_info.dart';
import 'character/details.dart';
import 'prebatle/prebattle.dart';
import '../state/states.dart';
import '../scene/common.dart';
import 'character/item_select_dialog.dart';
import 'ui/draggable_panel.dart';
import '../scene/game_dialog/game_dialog_controller.dart';
import 'history_panel.dart';
import 'npc_list.dart';
import 'character/merchant/merchant.dart';
import 'dialog/new_items.dart';
import 'dialog/new_journal.dart';
import '../game/data.dart';
import 'character/inventory/equipment_bar.dart';
import 'character/stats.dart';
import 'ui/bordered_icon_button.dart';
import 'location_panel.dart';

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
    this.action,
  });

  final bool enableHeroInfo;
  final bool enableNpcs;
  final bool enableLibrary;
  final bool enableCultivation;
  final bool enableAutoExhaust;
  final Widget? action;

  @override
  State<GameUIOverlay> createState() => _GameUIOverlayState();
}

class _GameUIOverlayState extends State<GameUIOverlay> {
  final Set<String> _prompts = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    // final bool autoCultivate = widget.enableAutoExhaust &&
    //     (GameData.game?['flags']['autoCultivate'] ?? false);
    // final bool autoWork = widget.enableAutoExhaust &&
    //     (GameData.game?['flags']['autoWork'] ?? false);

    // final hero = context.watch<HeroState>().hero;
    final hero = context.watch<HeroState>().hero;
    final showHeroInfo = widget.enableHeroInfo &&
        hero != null &&
        context.watch<HeroInfoVisibilityState>().isVisible;

    final money = (hero?['materials']['money'] ?? 0).toString();
    final shard = (hero?['materials']['shard'] ?? 0).toString();

    final content = context.watch<HoverContentState>().content;

    final enemyData = context.watch<EnemyState>().data;
    final showPrebattle = context.watch<EnemyState>().showPrebattle;
    final battleBackground = context.watch<EnemyState>().background;
    // final prebattlePreventClose =
    //     context.watch<EnemyState>().prebattlePreventClose;
    final onBattleStart = context.watch<EnemyState>().onBattleStart;
    final onBattleEnd = context.watch<EnemyState>().onBattleEnd;

    final (
      showMerchant,
      merchantMaterialMode,
      merchantUseShard,
      merchantData,
      merchantPriceFactor,
      merchantFilter,
      merchantType,
    ) = context.watch<MerchantState>().get();

    final showItemSelect = context.watch<ItemSelectState>().showItemSelect;
    final itemSelectCharacter = context.watch<ItemSelectState>().character;
    final itemSelectTitle = context.watch<ItemSelectState>().title;
    final itemSelectFilter = context.watch<ItemSelectState>().filter;
    final itemSelectMultiSelect = context.watch<ItemSelectState>().multiSelect;
    final itemSelectOnSelect = context.watch<ItemSelectState>().onSelect;
    final itemSelectSelectedItemsData =
        context.watch<ItemSelectState>().selectedItems;

    final newJournal = context.watch<NewJournalState>().journal;
    final newQuestCompleter = context.watch<NewJournalState>().completer;
    final newItems = context.watch<NewItemsState>().items;
    final newItemsCompleter = context.watch<NewItemsState>().completer;
    final newRank = context.watch<NewRankState>().rank;
    final newRankCompleter = context.watch<NewRankState>().completer;

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
    if (newJournal != null) {
      _prompts.add('journal');
    } else {
      _prompts.remove('journal');
    }

    final visiblePanels = context.watch<ViewPanelState>().visiblePanels;
    final panelPositions =
        context.watch<ViewPanelPositionState>().panelPositions;
    final List<Widget> panels = [];
    for (final panel in visiblePanels.keys) {
      // final arguments = visiblePanels[panel];
      switch (panel) {
        case ViewPanels.profile:
          final position =
              panelPositions[panel] ?? GameUI.profileWindowPosition;
          panels.add(
            DraggablePanel(
              title: engine.locale('information'),
              position: position,
              width: GameUI.profileWindowSize.x,
              height: GameUI.profileWindowSize.y,
              onTapDown: (offset) {
                context.read<ViewPanelState>().setUpFront(ViewPanels.profile);
                context
                    .read<ViewPanelPositionState>()
                    .set(ViewPanels.profile, position);
              },
              onDragUpdate: (details) {
                context
                    .read<ViewPanelPositionState>()
                    .update(ViewPanels.profile, details.delta);
              },
              onClose: () {
                context.read<ViewPanelState>().hide(ViewPanels.profile);
              },
              child: CharacterProfile(
                height: 340.0,
                character: hero,
                showIntimacy: false,
                showRelationships: false,
                showPosition: false,
                showPersonality: false,
              ),
            ),
          );
        case ViewPanels.details:
          final position =
              panelPositions[panel] ?? GameUI.detailsWindowPosition;
          panels.add(
            DraggablePanel(
              title: engine.locale('stats_and_inventory'),
              position: position,
              width: GameUI.profileWindowSize.x,
              height: GameUI.profileWindowSize.y,
              onTapDown: (offset) {
                context.read<ViewPanelState>().setUpFront(ViewPanels.details);
                context
                    .read<ViewPanelPositionState>()
                    .set(ViewPanels.details, position);
              },
              onDragUpdate: (details) {
                context
                    .read<ViewPanelPositionState>()
                    .update(ViewPanels.details, details.delta);
              },
              onClose: () {
                context.read<ViewPanelState>().hide(ViewPanels.details);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 5.0),
                child: CharacterDetails(character: hero),
              ),
            ),
          );
        case ViewPanels.memory:
          final position =
              context.watch<ViewPanelPositionState>().get(ViewPanels.memory) ??
                  GameUI.profileWindowPosition;
          panels.add(
            DraggablePanel(
              title: engine.locale('memory'),
              position: position,
              width: GameUI.profileWindowSize.x,
              height: GameUI.profileWindowSize.y,
              // titleHeight: 100,
              onTapDown: (offset) {
                context.read<ViewPanelState>().setUpFront(ViewPanels.memory);
                context
                    .read<ViewPanelPositionState>()
                    .set(ViewPanels.memory, position);
              },
              onDragUpdate: (details) {
                context.read<ViewPanelPositionState>().update(
                      ViewPanels.memory,
                      details.delta,
                    );
              },
              onClose: () {
                context.read<ViewPanelState>().hide(ViewPanels.memory);
              },
              child: CharacterMemory(character: hero, isHero: true),
            ),
          );
        case ViewPanels.journal:
          panels.add(JournalView(character: hero));
        case ViewPanels.workbench:
          panels.add(WorkbenchDialog());
        case ViewPanels.alchemy:
          panels.add(AlchemyDialog());
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
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
                    size: const Size(120, 120),
                    image: AssetImage('assets/images/${hero['icon']}'),
                    onPressed: (_) {},
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: GameUI.backgroundColor2,
                        height: 45,
                        width: screenSize.width - 120,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 10.0, top: 2.5, right: 5.0),
                              child: DynamicColorProgressBar(
                                value: hero['life'],
                                max: hero['stats']['lifeMax'],
                                height: 25.0,
                                width: 200.0,
                                showNumber: true,
                                showNumberAsPercentage: false,
                                label: engine.locale('stamina'),
                                colors: <Color>[
                                  Colors.yellow.shade400,
                                  Colors.yellow.shade900,
                                ],
                                // onMouseEnter: (rect) {
                                //   final content =
                                //       '${engine.locale('stamina')}: $life/$lifeMax';
                                //   context
                                //       .read<HoverContentState>()
                                //       .show(content, rect);
                                // },
                                // onMouseExit: () {
                                //   context.read<HoverContentState>().hide();
                                // },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: MouseRegion2(
                                // cursor: SystemMouseCursors.click,
                                // onTapUp: () {
                                //   context.read<HoverContentState>().hide();
                                //   if (widget.enableAutoExhaust) {
                                //     GameData.game?['flags']['autoWork'] =
                                //         !autoWork;
                                //     setState(() {});
                                //   }
                                // },
                                onMouseEnter: (rect) {
                                  String description =
                                      engine.locale('money_description');
                                  // if (widget.enableAutoExhaust) {
                                  //   description +=
                                  //       '\n \n<yellow>${engine.locale('autoWork')}: ${autoWork ? engine.locale('opened') : engine.locale('closed')}</>';
                                  // }
                                  context
                                      .read<HoverContentState>()
                                      .show(description, rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverContentState>().hide();
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 120.0,
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Text(
                                        money,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color:
                                              //  autoWork
                                              //     ? GameUI.foregroundColor
                                              //     :
                                              Colors.transparent,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Image(
                                          width: 20,
                                          height: 20,
                                          image: AssetImage(
                                              'assets/images/item/material/money.png')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: MouseRegion2(
                                // cursor: SystemMouseCursors.click,
                                // onTapUp: () {
                                //   context.read<HoverContentState>().hide();
                                //   if (widget.enableAutoExhaust) {
                                //     GameData.game?['flags']['autoCultivate'] =
                                //         !autoCultivate;
                                //     setState(() {});
                                //   }
                                // },
                                onMouseEnter: (rect) {
                                  String description =
                                      engine.locale('shard_description');
                                  // if (widget.enableAutoExhaust) {
                                  //   description +=
                                  //       '\n \n<yellow>${engine.locale('autoCultivate')}: ${autoCultivate ? engine.locale('opened') : engine.locale('closed')}</>';
                                  // }
                                  context
                                      .read<HoverContentState>()
                                      .show(description, rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverContentState>().hide();
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 120.0,
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: Text(
                                        shard,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color:
                                              //  autoCultivate
                                              //     ? GameUI.foregroundColor
                                              //     :
                                              Colors.transparent,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Image(
                                          width: 20,
                                          height: 20,
                                          image: AssetImage(
                                              'assets/images/item/material/shard.png')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: MouseRegion2(
                                onMouseEnter: (rect) {
                                  final data = hero!['materials'];
                                  final content = SizedBox(
                                    width: 200,
                                    height: 220,
                                    child: Column(
                                      children: kOtherMaterials
                                          .map(
                                            (id) => Row(
                                              children: [
                                                Image(
                                                  width: 20,
                                                  height: 20,
                                                  image: AssetImage(
                                                      'assets/images/item/material/$id.png'),
                                                ),
                                                Text('${engine.locale(id)}: '),
                                                SizedBox(
                                                  width: 120.0,
                                                  child: Text(
                                                      textAlign: TextAlign.end,
                                                      '${data[id] ?? 0}'),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  );
                                  context
                                      .read<HoverContentState>()
                                      .show(content, rect);
                                },
                                onMouseExit: () {
                                  context.read<HoverContentState>().hide();
                                },
                                child: Row(
                                  children: [
                                    const Image(
                                        width: 20,
                                        height: 20,
                                        image: AssetImage(
                                            'assets/images/item/material.png')),
                                  ],
                                ),
                              ),
                            ),
                            EquipmentBar(
                              character: hero,
                              gridSize: const Size(30.0, 30.0),
                            ),
                            BorderedIconButton(
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.all(2),
                              borderRadius: 5.0,
                              onPressed: () {
                                context
                                    .read<ViewPanelState>()
                                    .toogle(ViewPanels.profile);
                              },
                              onMouseEnter: (rect) {
                                context
                                    .read<HoverContentState>()
                                    .show(engine.locale('information'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/information.png'),
                              ),
                            ),
                            BorderedIconButton(
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.all(2),
                              borderRadius: 5.0,
                              onPressed: () {
                                context
                                    .read<ViewPanelState>()
                                    .toogle(ViewPanels.journal);
                              },
                              onMouseEnter: (rect) {
                                context
                                    .read<HoverContentState>()
                                    .show(engine.locale('journal'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverContentState>().hide();
                              },
                              child: const Image(
                                image:
                                    AssetImage('assets/images/icon/quest.png'),
                              ),
                            ),
                            BorderedIconButton(
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.all(2),
                              borderRadius: 5.0,
                              onPressed: () {
                                context
                                    .read<ViewPanelState>()
                                    .toogle(ViewPanels.details);
                              },
                              onMouseEnter: (rect) {
                                final Widget statsView = CharacterStats(
                                  title: engine.locale('stats'),
                                  character: hero,
                                  showNonBattleStats: false,
                                );
                                context.read<HoverContentState>().show(
                                      statsView,
                                      rect,
                                      direction:
                                          HoverContentDirection.bottomLeft,
                                    );
                              },
                              onMouseExit: () {
                                context.read<HoverContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/inventory.png'),
                              ),
                            ),
                            BorderedIconButton(
                              isEnabled: widget.enableCultivation,
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.all(2),
                              borderRadius: 5.0,
                              onPressed: () {
                                engine.context.read<HoverContentState>().hide();
                                engine.context
                                    .read<ViewPanelState>()
                                    .clearAll();
                                engine
                                    .pushScene(Scenes.cultivation, arguments: {
                                  'enableCultivate':
                                      engine.scene?.id == 'mainmenu',
                                });
                              },
                              onMouseEnter: (rect) {
                                final cultivationDescription =
                                    GameData.getPassivesDescription(hero);

                                context.read<HoverContentState>().show(
                                      cultivationDescription,
                                      rect,
                                      direction:
                                          HoverContentDirection.bottomLeft,
                                      textAlign: TextAlign.left,
                                    );
                              },
                              onMouseExit: () {
                                context.read<HoverContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/cultivate.png'),
                              ),
                            ),
                            BorderedIconButton(
                              isEnabled: widget.enableLibrary,
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.all(2),
                              borderRadius: 5.0,
                              onPressed: () {
                                engine.context.read<HoverContentState>().hide();
                                engine.context
                                    .read<ViewPanelState>()
                                    .clearAll();
                                engine.pushScene(Scenes.library, arguments: {
                                  'enableCardCraft':
                                      engine.scene?.id == Scenes.mainmenu,
                                  'enableScrollCraft':
                                      engine.scene?.id == Scenes.mainmenu,
                                });
                              },
                              onMouseEnter: (rect) {
                                context
                                    .read<HoverContentState>()
                                    .show(engine.locale('cardlibrary'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/library.png'),
                              ),
                            ),
                            BorderedIconButton(
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.all(2),
                              borderRadius: 5.0,
                              onPressed: () {
                                context.read<HoverContentState>().hide();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => Console(
                                    engine: engine,
                                    margin: const EdgeInsets.all(50.0),
                                    backgroundColor: GameUI.backgroundColor2,
                                  ),
                                );
                              },
                              onMouseEnter: (rect) {
                                context
                                    .read<HoverContentState>()
                                    .show(engine.locale('console'), rect);
                              },
                              onMouseExit: () {
                                context.read<HoverContentState>().hide();
                              },
                              child: const Image(
                                image: AssetImage(
                                    'assets/images/icon/unknown_item.png'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 75,
                        width: screenSize.width - 120,
                        child: Row(
                          children: [
                            HistoryPanel(width: 535, height: 75),
                            const Spacer(),
                            LocationPanel(width: 150, height: 75),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            if (widget.action != null)
              Positioned(
                right: 5.0,
                top: 5.0,
                child: Container(
                  width: GameUI.infoButtonSize.width,
                  height: GameUI.infoButtonSize.height,
                  margin: const EdgeInsets.all(2),
                  child: widget.action!,
                ),
              ),
            if (widget.enableNpcs)
              const Positioned(
                left: 10,
                top: 105,
                child: NpcList(),
              ),
            if (enemyData != null && showPrebattle)
              PreBattleDialog(
                hero: hero,
                enemy: enemyData,
                background: battleBackground,
                // prebattlePreventClose: prebattlePreventClose,
                ignoreRequirement: engine.scene?.id == Scenes.mainmenu,
                onBattleStart: onBattleStart,
                onBattleEnd: onBattleEnd,
              ),
            if (merchantData != null && showMerchant)
              MerchantDialog(
                merchantData: merchantData,
                useShard: merchantUseShard,
                materialMode: merchantMaterialMode,
                priceFactor: merchantPriceFactor,
                filter: merchantFilter,
                merchantType: merchantType,
              ),
            if (showItemSelect)
              ItemSelectDialog(
                character: itemSelectCharacter,
                title: itemSelectTitle,
                filter: itemSelectFilter,
                multiSelect: itemSelectMultiSelect,
                onSelect: itemSelectOnSelect,
                selectedItemsData: itemSelectSelectedItemsData,
              ),
            GameDialogController(),
            ...panels,
            if (_prompts.isNotEmpty)
              switch (_prompts.last) {
                'rank' => NewRank(rank: newRank!, completer: newRankCompleter),
                'journal' => NewJournal(
                    journalData: newJournal!, completer: newQuestCompleter),
                'item' =>
                  NewItems(itemsData: newItems!, completer: newItemsCompleter),
                _ => SizedBox.shrink(),
              },
            if (content != null) HoverInfo(content),
            // CustomCursor(
            //   width: screenSize.width,
            //   height: screenSize.height,
            // ),
          ],
        ),
      ),
    );
  }
}
