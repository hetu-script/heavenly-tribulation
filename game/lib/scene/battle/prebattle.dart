import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/richtext.dart';
import 'package:samsara/widgets/rich_text_builder2.dart';

import '../../view/avatar.dart';
import '../../engine.dart';
import '../../ui.dart';
import '../../data.dart';
import 'battlecard.dart';
import '../../view/hoverinfo.dart';
import '../../view/menu_item_builder.dart';
import '../../scene/card_library/card_library.dart';
import '../../common.dart';
import '../../dialog/game_dialog/game_dialog.dart';
import 'battle.dart';

class PreBattleDialog extends StatefulWidget {
  final dynamic heroData, enemyData;

  PreBattleDialog({
    required this.heroData,
    required this.enemyData,
  }) : super(key: GlobalKey());

  @override
  State<PreBattleDialog> createState() => _PreBattleDialogState();
}

class _PreBattleDialogState extends State<PreBattleDialog> {
  List<dynamic> _heroDecks = [];
  int _heroDeckCardLimit = 0;

  List<Widget> _heroDeck = [], _enemyDeck = [];
  final Map<String, String> _cardDescriptions = {};

  List heroBattleDeckCards = [], enemyBattleDeckCards = [];

  dynamic _hoveringCardData;
  Rect? _hoveringWidgetRect;

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
          name: engine.locale('prebattle.noDecks'),
        ),
      ];
    } else {
      final items = <PopupMenuEntry<int>>[];
      for (int i = 0; i < _heroDecks.length; i++) {
        final deckInfo = _heroDecks[i];
        if (deckInfo['cards'].length == _heroDeckCardLimit) {
          items.add(buildMenuItem(
            item: i,
            name: deckInfo['title'],
          ));
        }
      }
      if (items.isEmpty) {
        items.add(buildMenuItem(
          item: -1,
          name: engine.locale('prebattle.noDecks'),
        ));
      }
      return items;
    }
  }

  List<Widget> _createDeckCardWidgets(dynamic characterData) {
    List<BattleCard> widgetCards = [];
    final Map library = characterData['cardLibrary'];
    final List decks = characterData['battleDecks'];
    final int battleDeckIndex = characterData['battleDeckIndex'];
    if (battleDeckIndex >= 0) {
      final dynamic battleDeckData = decks[battleDeckIndex];
      final List deck = battleDeckData['cards'];
      assert(deck.length == _heroDeckCardLimit);
      widgetCards = List<BattleCard>.from(
        deck.map(
          (cardId) {
            final cardData = library[cardId];
            assert(cardData != null);
            final (_, extraDescription) =
                GameData.getDescriptionFromCardData(cardData);
            _cardDescriptions[cardData['id']] = extraDescription;
            return BattleCard(
              cardData: cardData,
              onMouseEnter: (cardData, widgetRect) {
                setState(() {
                  _hoveringCardData = cardData;
                  _hoveringWidgetRect = widgetRect;
                });
              },
              onMouseExit: () {
                setState(() {
                  _hoveringCardData = null;
                  _hoveringWidgetRect = null;
                });
              },
            );
          },
        ),
      );
    }
    return widgetCards;
  }

  List _getBattleDeckCardsData(dynamic characterData) {
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
    return deckCards;
  }

  void loadData() {
    _heroDecks = widget.heroData['battleDecks'];
    final rank = widget.heroData['cultivationRank'];
    _heroDeckCardLimit = getDeckCardLimitFromRank(rank);
    _heroDeck = _createDeckCardWidgets(widget.heroData);
    heroBattleDeckCards = _getBattleDeckCardsData(widget.heroData);
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
      stackChildren: [
        if (_hoveringCardData != null && _hoveringWidgetRect != null)
          HoverInfo(
            onSizeChanged: () {},
            text: buildFlutterRichText(
                _cardDescriptions[_hoveringCardData['id']]),
            hoveringRect: _hoveringWidgetRect!,
          ),
      ],
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('prebattle'),
          ),
          actions: const [CloseButton2()],
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
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Label(
                        engine.locale('prebattle.checkStats'),
                        width: 150.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                CardLibraryOverlay(deckSize: 4),
                          ),
                        );
                        setState(() {
                          loadData();
                        });
                      },
                      child: Label(
                        engine.locale('prebattle.editDeck'),
                        width: 150.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Container(
                      height: 32.0,
                      width: 200.0,
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
                              _heroDeck =
                                  _createDeckCardWidgets(widget.heroData);
                              heroBattleDeckCards =
                                  _getBattleDeckCardsData(widget.heroData);
                            });
                          },
                          itemBuilder: buildDeckSelectionPopUpMenuItems,
                          child: Label(
                            engine.locale('prebattle.selectDeck'),
                            width: 150.0,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: GameUI.borderRadius,
                    ),
                    height: 320.0,
                    width: 200.0,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: SizedBox(
                      height: 60.0,
                      child: ElevatedButton(
                        onPressed: () {
                          assert(enemyBattleDeckCards.isNotEmpty);

                          if (heroBattleDeckCards.isEmpty) {
                            GameDialog.show(
                              context: context,
                              dialogData: {
                                'lines': [
                                  engine.locale('deckbuilding.deckIsNotFull')
                                ],
                              },
                            );
                          } else {
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
                          }
                        },
                        child: Label(
                          engine.locale('start'),
                          width: 80.0,
                          textAlign: TextAlign.center,
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
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Label(
                        engine.locale('prebattle.checkStats'),
                        width: 150.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: GameUI.borderRadius,
                    ),
                    height: 320.0,
                    width: 200.0,
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
