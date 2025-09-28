import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../ui/bordered_icon_button.dart';
import '../avatar.dart';
import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import 'battlecard.dart';
import '../ui/menu_builder.dart';
import '../character/inventory/equipment_bar.dart';
import '../../scene/common.dart';
import '../../game/logic.dart';
import '../../state/states.dart';
import '../character/stats.dart';
import '../../scene/game_dialog/game_dialog_content.dart';
import '../../game/event_ids.dart';
import '../ui/close_button2.dart';

class PreBattleDialog extends StatefulWidget {
  /// 显示战斗准备对话框，注意对战己方不一定是英雄，所以这里需要传入己方角色
  const PreBattleDialog({
    super.key,
    required this.hero,
    required this.enemy,
    this.onBattleStart,
    this.onBattleEnd,
    this.ignoreRequirement = false,
  });

  final dynamic hero, enemy;

  final void Function()? onBattleStart;
  final void Function(bool, int)? onBattleEnd;
  final bool ignoreRequirement;

  @override
  State<PreBattleDialog> createState() => _PreBattleDialogState();
}

class _PreBattleDialogState extends State<PreBattleDialog> {
  final GlobalKey
      // _identifyStatsButtonKey = GlobalKey(),
      _identifyDeckButtonKey = GlobalKey();

  final menuController = fluent.FlyoutController();

  List<dynamic> _heroDecks = [];

  List<Widget> _heroDeck = [], _enemyDeck = [];

  // List heroBattleDeckCards = [];
  List enemyBattleDeckCards = [];

  String? _warning;

  int _availableIdentifyCount = 0;

  @override
  void initState() {
    super.initState();

    engine.addEventListener(Scenes.prebattle, GameEvents.heroPassivesUpdated,
        (args) {
      setState(() {});
    });

    final int playerMonthlyIdentifiedCards =
        GameData.game['playerMonthly']['identifiedEnemyCards'];
    final int playerMonthlyIdentifiedCardsCount =
        widget.hero['stats']['identifyCardsCountMonthly'];
    _availableIdentifyCount =
        playerMonthlyIdentifiedCardsCount - playerMonthlyIdentifiedCards;
    if (_availableIdentifyCount < 0) _availableIdentifyCount = 0;

    _heroDecks = widget.hero['battleDecks'];
    _heroDeck = _createDeckCardWidgets(widget.hero, isHero: true);
    // heroBattleDeckCards =
    //     _getBattleDeckCardsData(widget.heroData, isHero: true);
    _enemyDeck = _createDeckCardWidgets(widget.enemy);
    enemyBattleDeckCards = _getBattleDeckCardsData(widget.enemy);
  }

  @override
  void dispose() {
    engine.removeEventListener(Scenes.prebattle);

    menuController.dispose();
    super.dispose();
  }

  List<Widget> _createDeckCardWidgets(dynamic character,
      {bool isHero = false}) {
    List<BattleCard> widgetCards = [];
    final library = character['cardLibrary'];
    final List decks = character['battleDecks'];
    final int battleDeckIndex = character['battleDeckIndex'];
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
                data: cardData,
                character: character,
                isHero: isHero,
                cardInfoDirection: isHero
                    ? HoverContentDirection.rightTop
                    : HoverContentDirection.leftTop,
              );
            },
          ),
        );
      } else {
        engine.warn('Invalid battle deck index: $battleDeckIndex');
        character['battleDeckIndex'] = -1;
      }
    }
    if (isHero) {
      if (widgetCards.isEmpty) {
        _warning = engine.locale('prebattle_no_decks');
      } else {
        final String? info =
            GameLogic.checkDeckRequirement(widgetCards.map((widget) {
          return widget.data;
        }));
        _warning = info != null ? engine.locale(info) : null;
      }
    }
    return widgetCards;
  }

  List _getBattleDeckCardsData(dynamic character) {
    final List deckCards = [];
    final List decks = character['battleDecks'];
    final int battleDeckIndex = character['battleDeckIndex'];
    if (battleDeckIndex >= 0) {
      assert(decks.length > battleDeckIndex);
      final cardIds = decks[battleDeckIndex]['cards'];
      for (final cardId in cardIds) {
        final cardData = character['cardLibrary'][cardId];
        deckCards.add(cardData);
      }
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
                    character: widget.hero,
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
                    character: widget.hero,
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
                          onPressed: () {
                            context
                                .read<ViewPanelState>()
                                .toogle(ViewPanels.characterDetails);
                          },
                          onMouseEnter: (rect) {
                            context
                                .read<HoverContentState>()
                                .show(engine.locale('equipments'), rect);
                          },
                          onMouseExit: () {
                            context.read<HoverContentState>().hide();
                          },
                          child: const Image(
                            image:
                                AssetImage('assets/images/icon/inventory.png'),
                          ),
                        ),
                        BorderedIconButton(
                          size: GameUI.infoButtonSize,
                          padding: const EdgeInsets.only(right: 10.0),
                          onPressed: () {
                            engine.pushScene(Scenes.cultivation);
                          },
                          onMouseEnter: (rect) {
                            context
                                .read<HoverContentState>()
                                .show(engine.locale('skillTree'), rect);
                          },
                          onMouseExit: () {
                            context.read<HoverContentState>().hide();
                          },
                          child: const Image(
                            image:
                                AssetImage('assets/images/icon/cultivate.png'),
                          ),
                        ),
                        BorderedIconButton(
                          size: GameUI.infoButtonSize,
                          padding: const EdgeInsets.only(right: 10.0),
                          onPressed: () {
                            engine.pushScene(Scenes.library);
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
                            image: AssetImage('assets/images/icon/library.png'),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 10.0, bottom: 10.0),
                          child: fluent.FlyoutTarget(
                            controller: menuController,
                            child: fluent.FilledButton(
                              onPressed: () {
                                showFluentMenu(
                                    controller: menuController,
                                    items: _heroDecks.isEmpty
                                        ? {
                                            engine.locale('prebattle_no_decks'):
                                                -1,
                                          }
                                        : {
                                            for (var i = 0;
                                                i < _heroDecks.length;
                                                ++i)
                                              _heroDecks[i]['title']: i
                                          },
                                    onSelectedItem: (int index) {
                                      widget.hero['battleDeckIndex'] = index;
                                      _heroDeck = _createDeckCardWidgets(
                                        widget.hero,
                                        isHero: true,
                                      );
                                      setState(() {});
                                    });
                              },
                              child: Label(
                                '${engine.locale('decks')}: ${_heroDecks.length}',
                                width: 100.0,
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
                      child: fluent.FilledButton(
                        onPressed: () {
                          if (_warning != null && !widget.ignoreRequirement) {
                            GameDialogContent.show(context, _warning!);
                            return;
                          }
                          assert(enemyBattleDeckCards.isNotEmpty);
                          context.read<EnemyState>().setPrebattleVisible(false);
                          final arg = {
                            'id': Scenes.battle,
                            'hero': widget.hero,
                            'enemy': widget.enemy,
                            'onBattleStart': widget.onBattleStart,
                            'onBattleEnd': widget.onBattleEnd,
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
                    character: widget.enemy,
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
                              character: widget.enemy,
                              isHero: false,
                              showNonBattleStats: false,
                            );
                            context.read<HoverContentState>().show(
                                  statsView,
                                  rect,
                                  direction: HoverContentDirection.leftTop,
                                );
                          },
                          onMouseExit: () {
                            context.read<HoverContentState>().hide();
                          },
                          child: const Image(
                            image: AssetImage('assets/images/icon/stats.png'),
                          ),
                        ),
                        const Spacer(),
                        // Padding(
                        //   padding: EdgeInsets.only(right: 15.0),
                        //   child: fluent.FilledButton(
                        //     key: _identifyStatsButtonKey,
                        //     onPressed: () {},
                        //     onHover: (entered) {
                        //       if (entered) {
                        //         final hint = engine.locale('identifyStats');
                        //         final rect = getRenderRect(
                        //             _identifyStatsButtonKey.currentContext!);
                        //         context
                        //             .read<HoverContentState>()
                        //             .set(hint, rect);
                        //       } else {
                        //         context.read<HoverContentState>().hide();
                        //       }
                        //     },
                        //     child: Text(engine.locale('identifyStats')),
                        //   ),
                        // ),
                        Padding(
                          padding: EdgeInsets.only(right: 5.0),
                          child: fluent.FilledButton(
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
                                GameData.game['playerMonthly']
                                    ['identifiedEnemyCards'] += 1;
                                context.read<HoverContentState>().hide();
                                setState(() {
                                  _enemyDeck =
                                      _createDeckCardWidgets(widget.enemy);
                                });
                              } else {
                                GameDialogContent.show(
                                  context,
                                  engine.locale('identify_deck_reach_limit'),
                                );
                              }
                            },
                            child: Label(
                              engine.locale('identifyDeck'),
                              onMouseEnter: (rect) {
                                final hint =
                                    '${engine.locale('identifyDeck')}\n'
                                    '${engine.locale('available_count')}: <bold ${_availableIdentifyCount > 0 ? 'yellow' : 'grey'}>${_availableIdentifyCount.toString().padLeft(4)}</>\n'
                                    '<grey>${engine.locale('identify_deck_hint')}</>';
                                context.read<HoverContentState>().show(
                                      hint,
                                      rect,
                                      textAlign: TextAlign.left,
                                      direction:
                                          HoverContentDirection.topCenter,
                                    );
                              },
                              onMouseExit: () {
                                context.read<HoverContentState>().hide();
                              },
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
                    character: widget.enemy,
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
