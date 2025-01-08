import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/logic/battlecard.dart';
import 'package:samsara/ui/empty_placeholder.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/label.dart';
// import 'package:samsara/richtext.dart';
import 'package:samsara/widgets/rich_text_builder2.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/bordered_icon_button.dart';

import '../../view/avatar.dart';
import '../../engine.dart';
import '../../ui.dart';
import '../../data.dart';
import 'battlecard.dart';
// import '../../view/hoverinfo.dart';
import '../../view/menu_item_builder.dart';
import '../../scene/card_library/card_library.dart';
// import '../../common.dart';
// import '../../dialog/game_dialog/game_dialog.dart';
import 'battle.dart';
import '../../state/hover_info.dart';
import '../../view/character/equipments/equipment_bar.dart';
import '../../state/windows.dart';
import '../../state/hero.dart';

class PreBattleDialog extends StatefulWidget {
  final dynamic heroData, enemyData;

  final void Function()? onClose;

  PreBattleDialog({
    required this.heroData,
    required this.enemyData,
    this.onClose,
  }) : super(key: GlobalKey());

  @override
  State<PreBattleDialog> createState() => _PreBattleDialogState();
}

class _PreBattleDialogState extends State<PreBattleDialog> {
  List<dynamic> _heroDecks = [];

  List<Widget> _heroDeck = [], _enemyDeck = [];

  List heroBattleDeckCards = [], enemyBattleDeckCards = [];

  String? _warning;

  @override
  void initState() {
    super.initState();

    engine.pauseBGM();

    loadData();
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
    final Map library = characterData['cardLibrary'];
    final List decks = characterData['battleDecks'];
    final int battleDeckIndex = characterData['battleDeckIndex'];
    if (battleDeckIndex >= 0) {
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
            );
          },
        ),
      );
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
      final String? warning = checkDeckRequirement(characterData, deckCards);
      _warning = warning != null ? engine.locale(warning) : null;
    }
    return deckCards;
  }

  void loadData() {
    _heroDecks = widget.heroData['battleDecks'];
    _heroDeck = _createDeckCardWidgets(widget.heroData, isHero: true);
    heroBattleDeckCards =
        _getBattleDeckCardsData(widget.heroData, isHero: true);
    _enemyDeck = _createDeckCardWidgets(widget.enemyData);
    enemyBattleDeckCards = _getBattleDeckCardsData(widget.enemyData);
  }

  List<TextSpan> getCardRichDescription(dynamic cardData) {
    return buildRichText(cardData['extraDescription']);
  }

  @override
  Widget build(BuildContext context) {
    // final buttonKey = GlobalKey();

    return ResponsiveWindow(
      color: GameUI.backgroundColor,
      alignment: AlignmentDirectional.center,
      size: const Size(800.0, 640.0),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Avatar(
                    characterData: widget.heroData,
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: EquipmentBar(
                      characterData: widget.heroData,
                      gridSize: const Size(32.0, 32.0),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      BorderedIconButton(
                        size: GameUI.infoButtonSize,
                        padding: const EdgeInsets.only(right: 5.0),
                        onTap: () {
                          context.read<WindowPriorityState>().toogle('details');
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
                          image: AssetImage('assets/images/icon/inventory.png'),
                        ),
                      ),
                      BorderedIconButton(
                        size: GameUI.infoButtonSize,
                        padding: const EdgeInsets.only(right: 5.0),
                        onTap: () {
                          context.read<EnemyState>().show(false);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              requestFocus: true,
                              builder: (context) => CardLibraryOverlay(),
                            ),
                          );
                        },
                        onMouseEnter: (rect) {
                          context
                              .read<HoverInfoContentState>()
                              .set(engine.locale('card_library'), rect);
                        },
                        onMouseExit: () {
                          context.read<HoverInfoContentState>().hide();
                        },
                        icon: const Image(
                          image: AssetImage('assets/images/icon/library.png'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 10.0, left: 10.0, bottom: 10.0),
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
                                setState(() {
                                  widget.heroData['battleDeckIndex'] = index;
                                  _heroDeck = _createDeckCardWidgets(
                                      widget.heroData,
                                      isHero: true);
                                  heroBattleDeckCards = _getBattleDeckCardsData(
                                      widget.heroData,
                                      isHero: true);
                                });
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: GameUI.borderRadius,
                    ),
                    height: 320.0,
                    width: 240.0,
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
                          assert(enemyBattleDeckCards.isNotEmpty);

                          if (_warning != null) return;

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BattleSceneOverlay(
                                key: GlobalKey(),
                                heroData: widget.heroData,
                                enemyData: widget.enemyData,
                                heroDeck: heroBattleDeckCards
                                    .map((data) =>
                                        GameData.createBattleCardFromData(
                                          data,
                                          deepCopyData: true,
                                        ))
                                    .toList(),
                                enemyDeck: enemyBattleDeckCards
                                    .map((data) =>
                                        GameData.createBattleCardFromData(
                                          data,
                                          deepCopyData: true,
                                        ))
                                    .toList(),
                              ),
                            ),
                          );
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
                children: [
                  Avatar(
                    characterData: widget.enemyData,
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: EquipmentBar(
                      characterData: widget.enemyData,
                      gridSize: const Size(32.0, 32.0),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: GameUI.borderRadius,
                    ),
                    height: 320.0,
                    width: 240.0,
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
            ],
          ),
        ),
      ),
    );
  }
}
