import 'package:flutter/services.dart' show rootBundle;
import 'package:samsara/cardgame/playing_card.dart';
import 'package:json5/json5.dart';

import 'ui.dart';

abstract class GameData {
  static Map<String, dynamic> cardData = {};
  static Map<String, dynamic> animationData = {};
  static Map<String, dynamic> statusEffectData = {};

  static bool _isLoaded = false;
  static bool get isLoaded => _isLoaded;

  static Future<void> load() async {
    final cardsDataString =
        await rootBundle.loadString('scripts/game/cardgame/card.json5');
    cardData = JSON5.parse(cardsDataString);

    final animationDataString =
        await rootBundle.loadString('assets/data/animation.json5');
    animationData = JSON5.parse(animationDataString);

    final statusEffectDataString =
        await rootBundle.loadString('assets/data/status_effect.json5');
    statusEffectData = JSON5.parse(statusEffectDataString);

    _isLoaded = true;
  }

  static PlayingCard getBattleCard(String cardId) {
    assert(_isLoaded, 'GameData is not loaded yet!');
    assert(GameUI.isInitted, 'Game UI is not initted yet!');

    final data = cardData[cardId];
    assert(data != null, 'Failed to load card data: [$cardId]');
    final String id = data['id'];

    return PlayingCard(
      id: id,
      deckbuildingId: id,
      script: id,
      data: data,
      // title: data['title'][engine.locale.languageId],
      // description: data['rules'][engine.locale.languageId],
      size: GameUI.libraryCardSize,
      spriteId: 'card/library/$id.png',
      // focusedPriority: 1000,
      // illustrationSpriteId: 'cards/illustration/$id.png',
      // illustrationHeightRatio: kCardIllustrationHeightRatio,
      // showTitle: true,
      // titleStyle: const ScreenTextStyle(
      //   colorTheme: ScreenTextColorTheme.light,
      //   anchor: Anchor.topCenter,
      //   padding: EdgeInsets.only(
      //       top: kLibraryCardHeight * kCardIllustrationHeightRatio),
      //   textStyle: TextStyle(fontSize: 16),
      // ),
      // showDescription: true,
      // descriptionStyle: const ScreenTextStyle(
      //   colorTheme: ScreenTextColorTheme.dark,
      // ),
    );
  }
}
