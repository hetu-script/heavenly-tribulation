import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/dynamic_color_progressbar.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';
import 'package:samsara/markdown_wiki.dart';

import 'ui/avatar.dart';
import 'character/profile.dart';
import 'character/memory.dart';
import '../engine.dart';
import 'character/journal.dart';
import '../ui.dart';
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
import '../data/game.dart';
import 'character/inventory/equipment_bar.dart';
import 'ui/bordered_icon_button.dart';
import 'ui/close_button2.dart';
import '../scene/organization/meeting.dart';
import 'journal_panel.dart';
import 'dialog/new_rank.dart';
import 'view/alchemy.dart';
import 'view/workshop.dart';
import 'ui/responsive_view.dart';
import '../logic/logic.dart';

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
    this.enableLibrary = true,
    this.enableCultivation = true,
    this.showNpcs = false,
    this.showActiveJournal = false,
    this.actions,
  });

  final bool enableHeroInfo;
  final bool showNpcs;
  final bool enableLibrary;
  final bool enableCultivation;
  final bool showActiveJournal;
  final List<Widget>? actions;

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

    final hoverContent = context.watch<HoverContentState>().content;

    final enemyData = context.watch<EnemyState>().data;
    final showPrebattle = context.watch<EnemyState>().showPrebattle;
    final battleBackground = context.watch<EnemyState>().background;
    final loseOnEscape = context.watch<EnemyState>().loseOnEscape;
    final onBattleStart = context.watch<EnemyState>().onBattleStart;
    final onBattleEnd = context.watch<EnemyState>().onBattleEnd;

    final showMerchant = context.watch<MerchantState>().showMerchant;
    final merchantMaterialMode = context.watch<MerchantState>().materialMode;
    final merchantUseShard = context.watch<MerchantState>().useShard;
    final merchantData = context.watch<MerchantState>().merchantData;
    final merchantPriceFactor = context.watch<MerchantState>().priceFactor;
    final merchantFilter = context.watch<MerchantState>().filter;
    final merchantType = context.watch<MerchantState>().merchantType;
    final allowManualReplenish =
        context.watch<MerchantState>().allowManualReplenish;

    final showItemSelect = context.watch<ItemSelectState>().showItemSelect;
    final itemSelectCharacter = context.watch<ItemSelectState>().character;
    final itemSelectTitle = context.watch<ItemSelectState>().title;
    final itemSelectFilter = context.watch<ItemSelectState>().filter;
    final itemSelectMultiSelect = context.watch<ItemSelectState>().multiSelect;
    final itemSelectOnSelect = context.watch<ItemSelectState>().onSelect;
    final itemSelectSelectedItemsData =
        context.watch<ItemSelectState>().selectedItems;

    final showMeeting = context.watch<MeetingState>().showMeeting;
    final meetingPeople = context.watch<MeetingState>().people;
    final showExitButton = context.watch<MeetingState>().showExitButton;

    final journal = context.watch<JournalPromptState>().journal;
    final selections = context.watch<JournalPromptState>().selections;
    final journalPromptCompleter =
        context.watch<JournalPromptState>().completer;
    final items = context.watch<ItemsPromptState>().items;
    final itemsPromptCompleter = context.watch<ItemsPromptState>().completer;
    final rank = context.watch<RankPromptState>().rank;
    final rankPromptCompleter = context.watch<RankPromptState>().completer;

    if (rank != null) {
      _prompts.add('rank');
    } else {
      _prompts.remove('rank');
    }
    if (items != null) {
      _prompts.add('item');
    } else {
      _prompts.remove('item');
    }
    if (journal != null) {
      _prompts.add('journal');
    } else {
      _prompts.remove('journal');
    }

    final visiblePanels = context.watch<ViewPanelState>().visiblePanels;
    GameData.isInteractable = visiblePanels.isEmpty;
    final panelPositions =
        context.watch<ViewPanelPositionState>().panelPositions;
    final List<Widget> panels = [];
    for (final panel in visiblePanels.keys) {
      final arguments = visiblePanels[panel];
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
              title: engine.locale('statsAndInventory'),
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
          panels.add(JournalView(
            character: hero,
            selectedId: arguments?['selectedId'],
          ));
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
                    onPressed: (_) {
                      context.read<ViewPanelState>().toogle(ViewPanels.profile);
                    },
                    onEnter: (rect) {
                      context
                          .read<HoverContentState>()
                          .show(GameData.hero['name'], rect);
                    },
                    onExit: () {
                      context.read<HoverContentState>().hide();
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: GameUI.backgroundColor,
                        height: 35,
                        width: screenSize.width - 120,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 10.0, top: 2.5, right: 5.0),
                              child: DynamicColorProgressBar(
                                value: hero['life'].toInt(),
                                max: hero['stats']['lifeMax'].toInt(),
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
                                onEnter: (rect) {
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
                                onExit: () {
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
                                      decoration: GameUI.boxDecoration,
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
                                onEnter: (rect) {
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
                                onExit: () {
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
                                onEnter: (rect) {
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
                                onExit: () {
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
                              onEnter: (rect) {
                                context
                                    .read<HoverContentState>()
                                    .show(engine.locale('information'), rect);
                              },
                              onExit: () {
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
                              onEnter: (rect) {
                                final ongoingJournals = GameData
                                    .hero['journals'].values
                                    .where((journal) {
                                  return !journal['isFinished'];
                                }).length;
                                context.read<HoverContentState>().show(
                                      '${engine.locale('journal')}\n${engine.locale('ongoingJournals')}: $ongoingJournals',
                                      rect,
                                      textAlign: TextAlign.left,
                                    );
                              },
                              onExit: () {
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
                              onEnter: (rect) {
                                final level = GameData.hero['level'];
                                final levelString =
                                    '${engine.locale('level')}: $level';
                                final rank = GameData.hero['rank'];
                                final rankString =
                                    '${engine.locale('rank')}: ${engine.locale('cultivationRank_$rank')}';
                                final statsDesc =
                                    '${engine.locale('statsAndInventory')}\n$levelString\n$rankString';
                                context.read<HoverContentState>().show(
                                      statsDesc,
                                      rect,
                                      textAlign: TextAlign.left,
                                    );
                              },
                              onExit: () {
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
                                context.read<ViewPanelState>().clearAll();
                                engine
                                    .pushScene(Scenes.cultivation, arguments: {
                                  'enableCultivate':
                                      engine.scene?.id == 'mainmenu',
                                });
                              },
                              onEnter: (rect) {
                                final exp = GameData.hero['exp'];
                                final expForNextLevel = GameLogic.expForLevel(
                                    GameData.hero['level']);
                                final desc =
                                    '${engine.locale('meditateAndTalentTree')}\n'
                                    '${engine.locale('exp')}: $exp/$expForNextLevel';
                                // final cultivationDescription =
                                //     GameData.getPassivesDescription(
                                //         title: title);
                                context.read<HoverContentState>().show(
                                      desc,
                                      rect,
                                      direction:
                                          HoverContentDirection.bottomLeft,
                                      textAlign: TextAlign.left,
                                    );
                              },
                              onExit: () {
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
                                context.read<HoverContentState>().hide();
                                context.read<ViewPanelState>().clearAll();
                                engine.pushScene(Scenes.library, arguments: {
                                  'enableCardCraft':
                                      engine.scene?.id == Scenes.mainmenu,
                                  'enableScrollCraft':
                                      engine.scene?.id == Scenes.mainmenu,
                                });
                              },
                              onEnter: (rect) {
                                final cardCount =
                                    GameData.hero['cardLibrary'].length;
                                final deckCount =
                                    GameData.hero['battleDecks'].length;
                                context.read<HoverContentState>().show(
                                      '${engine.locale('cardlibrary')}\n'
                                      '${engine.locale('cardCount')}: $cardCount\n'
                                      '${engine.locale('deckCount')}: $deckCount',
                                      rect,
                                      textAlign: TextAlign.left,
                                    );
                              },
                              onExit: () {
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
                                  builder: (context) => ResponsiveView(
                                    margin: const EdgeInsets.all(50.0),
                                    child: MarkdownWiki(
                                      engine: engine,
                                      treeNodes: GameData.wikiTreeNodes,
                                      closeButton: CloseButton2(),
                                    ),
                                  ),
                                );
                              },
                              onEnter: (rect) {
                                context
                                    .read<HoverContentState>()
                                    .show(engine.locale('wiki'), rect);
                              },
                              onExit: () {
                                context.read<HoverContentState>().hide();
                              },
                              child: const Image(
                                image:
                                    AssetImage('assets/images/icon/wiki.png'),
                              ),
                            ),
                            BorderedIconButton(
                              size: GameUI.infoButtonSize,
                              padding: const EdgeInsets.all(2),
                              borderRadius: 5.0,
                              onPressed: () {
                                context.read<HoverContentState>().hide();
                                GameUI.showConsole(context);
                              },
                              onEnter: (rect) {
                                context
                                    .read<HoverContentState>()
                                    .show(engine.locale('console'), rect);
                              },
                              onExit: () {
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
                        height: 80,
                        width: screenSize.width - 120,
                        child: Row(
                          children: [
                            HistoryPanel(width: 535, height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (showHeroInfo && widget.showActiveJournal)
              Positioned(top: 30.0, right: 0, child: JournalPanel()),
            if (widget.actions != null)
              Positioned(
                right: 2.5,
                top: 2.5,
                child: Row(
                  children: widget.actions!,
                ),
              ),
            if (widget.showNpcs)
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
                loseOnEscape: loseOnEscape,
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
                allowManualReplenish: allowManualReplenish,
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
            if (showMeeting && meetingPeople.isNotEmpty)
              Meeting(people: meetingPeople, showExitButton: showExitButton),
            ...panels,
            if (_prompts.isNotEmpty)
              switch (_prompts.last) {
                'rank' => NewRank(
                    rank: rank!,
                    completer: rankPromptCompleter,
                  ),
                'journal' => NewJournal(
                    journal: journal!,
                    selections: selections,
                    completer: journalPromptCompleter,
                  ),
                'item' => NewItems(
                    itemsData: items!,
                    completer: itemsPromptCompleter,
                  ),
                _ => SizedBox.shrink(),
              },
            GameDialogController(),
            if (hoverContent != null) HoverInfo(hoverContent),
          ],
        ),
      ),
    );
  }
}
