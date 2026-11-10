import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../data/game.dart';
import '../../global.dart';
import '../../scene/dungeon/dungeon_controller.dart';
import '../ui/responsive_view.dart';

enum DungeonStartChoice { start, adjust }

class DungeonStartDialog extends StatelessWidget {
  const DungeonStartDialog({super.key});

  static Future<DungeonStartChoice?> show(BuildContext context) {
    return showDialog<DungeonStartChoice>(
      context: context,
      builder: (_) => const DungeonStartDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckIndex = DungeonController.prepareBattleDeck();
    final decks = GameData.hero['battleDecks'] as List;
    final hasDeck = deckIndex >= 0;
    final deck = hasDeck ? decks[deckIndex] : null;
    final title = deck?['title'] ?? engine.locale('none');
    final cardCount = deck?['cards']?.length ?? 0;

    return ResponsiveView(
      width: 440,
      height: 310,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('dungeonStartTitle')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${engine.locale('dungeonCurrentDeck')}: $title'),
              const SizedBox(height: 12),
              Text('${engine.locale('dungeonDeckCardCount')}: $cardCount'),
              const SizedBox(height: 12),
              Text(
                hasDeck
                    ? engine.locale('dungeonDefaultFillHint')
                    : engine.locale('dungeonNoAvailableDeck'),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  fluent.Button(
                    onPressed: () => Navigator.pop(
                      context,
                      DungeonStartChoice.adjust,
                    ),
                    child: Text(engine.locale('adjustDeck')),
                  ),
                  fluent.Button(
                    onPressed: () => Navigator.pop(context),
                    child: Text(engine.locale('cancel')),
                  ),
                  fluent.Button(
                    onPressed: hasDeck
                        ? () => Navigator.pop(
                              context,
                              DungeonStartChoice.start,
                            )
                        : null,
                    child: Text(engine.locale('startDungeon')),
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
