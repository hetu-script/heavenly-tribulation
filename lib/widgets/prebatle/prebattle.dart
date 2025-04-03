import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/bordered_icon_button.dart';

import '../avatar.dart';
import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import 'battlecard.dart';
import '../menu_item_builder.dart';
import '../character/inventory/equipment_bar.dart';
import '../../scene/common.dart';
import '../../game/logic.dart';
import '../../state/states.dart';
import '../character/stats.dart';
import '../../scene/game_dialog/game_dialog_content.dart';

class PreBattleDialog extends StatefulWidget {
  final dynamic heroData, enemyData;

  /// 显示战斗准备对话框，注意对战己方不一定是英雄，所以这里需要传入己方角色
  const PreBattleDialog({
    super.key,
    required this.heroData,
    required this.enemyData,
  });

  @override
  State<PreBattleDialog> createState() => _PreBattleDialogState();
}

class _PreBattleDialogState extends State<PreBattleDialog> {
  final GlobalKey
      // _identifyStatsButtonKey = GlobalKey(),
      _identifyDeckButtonKey = GlobalKey();

  List<dynamic> _heroDecks = [];

  List<Widget> _heroDeck = [], _enemyDeck = [];

  // List heroBattleDeckCards = [];
  List enemyBattleDeckCards = [];

  String? _warning;

  int _availableIdentifyCount = 0;

  @override
  void initState() {
    super.initState();

    final int playerMonthlyIdentifiedCards =
        GameData.gameData['playerMonthly']['identifiedEnemyCards'];
    final int playerMonthlyIdentifiedCardsCount =
        widget.heroData['stats']['identifyCardsCountMonthly'];
    _availableIdentifyCount =
        playerMonthlyIdentifiedCardsCount - playerMonthlyIdentifiedCards;
    if (_availableIdentifyCount < 0) _availableIdentifyCount = 0;

    _heroDecks = widget.heroData['battleDecks'];
    _heroDeck = _createDeckCardWidgets(widget.heroData, isHero: true);
    // heroBattleDeckCards =
    //     _getBattleDeckCardsData(widget.heroData, isHero: true);
    _enemyDeck = _createDeckCardWidgets(widget.enemyData);
    enemyBattleDeckCards = _getBattleDeckCardsData(widget.enemyData);
  }

  List<PopupMenuEntry<int>> buildDeckSelectionPopUpMenuItems(
      BuildContext context) {
    if (_heroDecks.isEmpty) {
      return <PopupMenuEntry<int>>[
        buildMenuItem(
          item: -1,
          name: engine.locale('prebattle_no_decks'),
        ),
      ];
    } else {
      final items = <PopupMenuEntry<int>>[];
      for (int i = 0; i < _heroDecks.length; i++) {
        final deckInfo = _heroDecks[i];
        items.add(buildMenuItem(
          item: i,
          name: deckInfo['title'],
        ));
      }
      if (items.isEmpty) {
        items.add(buildMenuItem(
          item: -1,
          name: engine.locale('prebattle_no_decks'),
        ));
      }
      return items;
    }
  }

  List<Widget> _createDeckCardWidgets(dynamic characterData,
      {bool isHero = false}) {
    List<BattleCard> widgetCards = [];
    final library = characterData['cardLibrary'];
    final List decks = characterData['battleDecks'];
    final int battleDeckIndex = characterData['battleDeckIndex'];
    if (battleDeckIndex != -1) {
      if (battleDeckIndex < decks.length) {
        final dynamic battleDeckData = decks[battleDeckIndex];
        final List deck = battleDeckData['cards'];
        widgetCards = List<BattleCard>.from(
          deck.map(
            (cardId) {
              final cardData = library[cardId];
              assert(cardData != null);
              return BattleCard(
                cardData: cardData,
                characterData: characterData,
                isHero: isHero,
                cardInfoDirection: isHero
                    ? HoverInfoDirection.rightTop
                    : HoverInfoDirection.leftTop,
              );
            },
          ),
        );
      } else {
        engine.warn('Invalid battle deck index: $battleDeckIndex');
        characterData['battleDeckIndex'] = -1;
      }
    }
    return widgetCards;
  }

  List _getBattleDeckCardsData(dynamic characterData, {bool isHero = false}) {
    final List deckCards = [];
    final List decks = characterData['battleDecks'];
    final int battleDeckIndex = characterData['battleDeckIndex'];
    if (battleDeckIndex >= 0) {
      assert(decks.length > battleDeckIndex);
      final cardIds = decks[battleDeckIndex]['cards'];
      for (final cardId in cardIds) {
        final cardData = characterData['cardLibrary'][cardId];
        deckCards.add(cardData);
      }
    }
    if (isHero) {
      final String? info = GameLogic.checkDeckRequirement(deckCards);
      _warning = info != null ? engine.locale(info) : null;
    }
    return deckCards;
  }

  @override
  Widget build(BuildContext context) {
    // final buttonKey = GlobalKey();

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 1080.0,
      height: 640.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('prebattle'),
          ),
          actions: [
            CloseButton2(
              onPressed: () {
                context.read<EnemyState>().clear();
              },
            )
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Avatar(
                    margin: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                    characterData: widget.heroData,
                  ),
                  Avatar(
                    margin: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                    showPlaceholder: true,
                  ),
                  Avatar(
                    margin: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                    showPlaceholder: true,
                  ),
                  Avatar(
                    margin: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                    showPlaceholder: true,
                  ),
                  Avatar(
                    margin: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                    showPlaceholder: true,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EquipmentBar(
                    type: ItemType.player,
                    characterData: widget.heroData,
                    gridSize: const Size(30.0, 30.0),
                  ),
                  Container(
                    padding: EdgeInsets.all(5.0),
                    width: 280.0,
                    child: Row(
                      children: [
                        BorderedIconButton(
                          size: GameUI.infoButtonSize,
                          padding: const EdgeInsets.only(right: 10.0),
                          onTapUp: () {
                            context
                                .read<ViewPanelState>()
                                .toogle(ViewPanels.characterDetails);
                          },
                          onMouseEnter: (rect) {
                            context
                                .read<HoverInfoContentState>()
                                .show(engine.locale('build'), rect);
                          },
                          onMouseExit: () {
                            context.read<HoverInfoContentState>().hide();
                          },
                          child: const Image(
                            image:
                                AssetImage('assets/images/icon/inventory.png'),
                          ),
                        ),
                        BorderedIconButton(
                          size: GameUI.infoButtonSize,
                          padding: const EdgeInsets.only(right: 10.0),
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
                            image: AssetImage('assets/images/icon/library.png'),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 10.0, bottom: 10.0),
                          child: Container(
                            height: 32.0,
                            width: 110.0,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(5.0),
                              border: Border.all(color: Colors.white),
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: PopupMenuButton<int>(
                                tooltip: '',
                                offset: const Offset(-8.0, 32.0),
                                onSelected: (int index) {
                                  widget.heroData['battleDeckIndex'] = index;
                                  _heroDeck = _createDeckCardWidgets(
                                      widget.heroData,
                                      isHero: true);
                                  // heroBattleDeckCards = _getBattleDeckCardsData(
                                  //     widget.heroData,
                                  //     isHero: true);
                                  setState(() {});
                                },
                                itemBuilder: buildDeckSelectionPopUpMenuItems,
                                child: Label(
                                  engine.locale('decks'),
                                  width: 150.0,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: GameUI.borderRadius,
                    ),
                    height: 435.0,
                    width: 270.0,
                    child: _heroDeck.isNotEmpty
                        ? ListView(
                            shrinkWrap: true,
                            // scrollDirection: Axis.horizontal,
                            children: _heroDeck,
                          )
                        : EmptyPlaceholder(engine.locale('empty')),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image(
                    image: AssetImage('assets/images/battle/versus.png'),
                    width: 200,
                    height: 200,
                  ),
                  const Spacer(),
                  Label(
                    _warning ?? '',
                    textStyle: TextStyle(color: Colors.red),
                    textAlign: TextAlign.left,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: SizedBox(
                      height: 50.0,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_warning != null && !kDebugMode) return;

                          assert(enemyBattleDeckCards.isNotEmpty);
                          context.read<EnemyState>().setPrebattleVisible(false);
                          final arg = {
                            'id': Scenes.battle,
                            'hero': widget.heroData,
                            'enemy': widget.enemyData,
                          };
                          engine.pushScene(Scenes.battle, arguments: arg);
                        },
                        child: Label(
                          engine.locale('start'),
                          width: 80.0,
                          textAlign: TextAlign.center,
                          textStyle: TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EquipmentBar(
                    type: ItemType.npc,
                    characterData: widget.enemyData,
                    gridSize: const Size(30.0, 30.0),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    width: 280.0,
                    child: Row(
                      children: [
                        BorderedIconButton(
                          size: GameUI.infoButtonSize,
                          padding: const EdgeInsets.only(left: 5.0),
                          onMouseEnter: (rect) {
                            final Widget statsView = CharacterStats(
                              characterData: widget.enemyData,
                              isHero: false,
                              showNonBattleStats: false,
                            );
                            context.read<HoverInfoContentState>().show(
                                  statsView,
                                  rect,
                                  direction: HoverInfoDirection.leftTop,
                                );
                          },
                          onMouseExit: () {
                            context.read<HoverInfoContentState>().hide();
                          },
                          child: const Image(
                            image: AssetImage('assets/images/icon/stats.png'),
                          ),
                        ),
                        const Spacer(),
                        // Padding(
                        //   padding: EdgeInsets.only(right: 15.0),
                        //   child: ElevatedButton(
                        //     key: _identifyStatsButtonKey,
                        //     onPressed: () {},
                        //     onHover: (entered) {
                        //       if (entered) {
                        //         final hint = engine.locale('identifyStats');
                        //         final rect = getRenderRect(
                        //             _identifyStatsButtonKey.currentContext!);
                        //         context
                        //             .read<HoverInfoContentState>()
                        //             .set(hint, rect);
                        //       } else {
                        //         context.read<HoverInfoContentState>().hide();
                        //       }
                        //     },
                        //     child: Text(engine.locale('identifyStats')),
                        //   ),
                        // ),
                        Padding(
                          padding: EdgeInsets.only(right: 5.0),
                          child: ElevatedButton(
                            key: _identifyDeckButtonKey,
                            onPressed: () {
                              if (_availableIdentifyCount > 0) {
                                bool identified = false;
                                for (final card in enemyBattleDeckCards) {
                                  if (card['isIdentified'] != true) {
                                    card['isIdentified'] = true;
                                    identified = true;
                                    break;
                                  }
                                }
                                if (!identified) {
                                  GameDialogContent.show(
                                    context,
                                    engine
                                        .locale('identify_deck_identifed_all'),
                                  );
                                  return;
                                }
                                engine
                                    .play('hammer-hitting-an-anvil-25390.mp3');
                                --_availableIdentifyCount;
                                GameData.gameData['playerMonthly']
                                    ['identifiedEnemyCards'] += 1;
                                context.read<HoverInfoContentState>().hide();
                                setState(() {
                                  _enemyDeck =
                                      _createDeckCardWidgets(widget.enemyData);
                                });
                              } else {
                                GameDialogContent.show(
                                  context,
                                  engine.locale('identify_deck_reach_limit'),
                                );
                              }
                            },
                            onHover: (entered) {
                              if (entered) {
                                final hint =
                                    '${engine.locale('identifyDeck')}\n'
                                    '${engine.locale('available_count')}: <bold ${_availableIdentifyCount > 0 ? 'yellow' : 'grey'}>${_availableIdentifyCount.toString().padLeft(4)}</>\n'
                                    '<grey>${engine.locale('identify_deck_hint')}</>';
                                final rect = getRenderRect(
                                    _identifyDeckButtonKey.currentContext!);
                                context.read<HoverInfoContentState>().show(
                                      hint,
                                      rect,
                                      textAlign: TextAlign.left,
                                      direction: HoverInfoDirection.topCenter,
                                    );
                              } else {
                                context.read<HoverInfoContentState>().hide();
                              }
                            },
                            child: Text(engine.locale('identifyDeck')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: GameUI.borderRadius,
                    ),
                    height: 435.0,
                    width: 270.0,
                    child: _enemyDeck.isNotEmpty
                        ? ListView(
                            shrinkWrap: true,
                            // scrollDirection: Axis.horizontal,
                            children: _enemyDeck,
                          )
                        : EmptyPlaceholder(engine.locale('empty')),
                  ),
                ],
              ),
              Column(
                children: [
                  Avatar(
                    margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                    characterData: widget.enemyData,
                  ),
                  Avatar(
                    margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                    showPlaceholder: true,
                  ),
                  Avatar(
                    margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                    showPlaceholder: true,
                  ),
                  Avatar(
                    margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                    showPlaceholder: true,
                  ),
                  Avatar(
                    margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                    showPlaceholder: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
