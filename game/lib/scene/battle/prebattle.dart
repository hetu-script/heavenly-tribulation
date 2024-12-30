import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/richtext.dart';

import '../../view/avatar.dart';
import '../../engine.dart';
import '../../ui.dart';
import 'battlecard.dart';
import '../../view/hoverinfo.dart';

class PreBattleDialog extends StatefulWidget {
  final dynamic heroData, enemyData;

  const PreBattleDialog({
    super.key,
    required this.heroData,
    required this.enemyData,
  });

  @override
  State<PreBattleDialog> createState() => _PreBattleDialogState();
}

class _PreBattleDialogState extends State<PreBattleDialog> {
  List<Widget> _heroDeck = [], _enemyDeck = [];

  dynamic _hoveringCardData;
  Rect? _hoveringWidgetRect;

  @override
  void initState() {
    super.initState();

    loadData();
  }

  List<BattleCard> _loadData(dynamic characterData) {
    List<BattleCard> cards = [];
    final List heroDecks = characterData['battleDecks'];
    final Map heroLibrary = characterData['cardLibrary'];
    final int? battleDeckIndex = characterData['battleDeckIndex'];
    if (battleDeckIndex != null) {
      final dynamic battleDeckData = heroDecks[battleDeckIndex];
      assert(battleDeckData != null);
      final List deck = battleDeckData['cards'];
      cards = List<BattleCard>.from(
        deck.map(
          (cardId) {
            final cardData = heroLibrary[cardId];
            assert(cardData != null);
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
    return cards;
  }

  void loadData() {
    _heroDeck = _loadData(widget.heroData);
    _enemyDeck = _loadData(widget.enemyData);
  }

  InlineSpan getCardRichDescription(dynamic cardData) {
    return TextSpan(text: cardData['name']);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      color: kBackgroundColor,
      alignment: AlignmentDirectional.center,
      size: const Size(800.0, 640.0),
      stackChildren: [
        if (_hoveringCardData != null && _hoveringWidgetRect != null)
          HoverInfo(
            onSizeChanged: () {},
            text: getCardRichDescription(_hoveringCardData),
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: kBorderRadius,
                    ),
                    height: 300.0,
                    width: 200.0,
                    child: ListView(
                      shrinkWrap: true,
                      // scrollDirection: Axis.horizontal,
                      children: _heroDeck,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Label(
                        engine.locale('prebattle.selectDeck'),
                        width: 150.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Label(
                        engine.locale('prebattle.checkDecks'),
                        width: 150.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                        onPressed: () {},
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: kBorderRadius,
                    ),
                    height: 300.0,
                    width: 200.0,
                    child: ListView(
                      shrinkWrap: true,
                      // scrollDirection: Axis.horizontal,
                      children: _enemyDeck,
                    ),
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
