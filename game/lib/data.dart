import 'package:flutter/services.dart' show rootBundle;
import 'package:samsara/cardgame/card.dart';
import 'package:json5/json5.dart';
import 'package:samsara/samsara.dart';

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

  static Card getSiteCard(dynamic siteData) {
    final id = siteData['id'];
    final card = Card(
      id: id,
      deckId: id,
      data: siteData,
      anchor: Anchor.center,
      borderRadius: 15.0,
      illustrationSpriteId: siteData['image'],
      spriteId: 'location/site/site_frame.png',
      title: siteData['name'],
      titleStyle: ScreenTextStyle(textStyle: const TextStyle(fontSize: 20.0)),
      showTitle: true,
      enablePreview: true,
      focusOnPreviewing: true,
      focusedPriority: 500,
      focusedSize: GameUI.siteCardFocusedSize,
      focusedOffset: Vector2(
          (GameUI.siteCardFocusedSize.x - GameUI.siteCardSize.x) / 2,
          (GameUI.siteCardSize.y - GameUI.siteCardFocusedSize.y) / 2),
    );
    return card;
  }

  static Card getBattleCard(String cardId) {
    assert(_isLoaded, 'GameData is not loaded yet!');
    assert(GameUI.isInitted, 'Game UI is not initted yet!');

    final data = cardData[cardId];
    assert(data != null, 'Failed to load card data: [$cardId]');
    final String id = data['id'];

    return Card(
      id: id,
      deckId: id,
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

abstract class PresetDecks {
  static List<Card> _getCards(List<String> cardIds) {
    return cardIds.map((e) => GameData.getBattleCard(e)).toList();
  }

  static const List<String> _basic = [
    'defend_normal',
    'attack_normal',
    'attack_normal',
    'attack_normal',
  ];

  static const List<String> _blade_1 = [
    'defend_normal',
    'blade_4',
    'blade_3',
    'blade_1',
  ];

  static const List<String> _blade_2 = [
    'blade_4',
    'blade_6',
    'blade_7',
    'blade_8',
  ];

  static const List<String> _blade_3 = [
    'blade_9',
    'blade_10',
    'blade_7',
    'blade_8',
  ];

  static const _allDecks = [
    _basic,
    ..._bladeDecks,
  ];

  static const _bladeDecks = [
    _blade_1,
    _blade_2,
    _blade_3,
  ];

  static List<Card> get random => _getCards(_allDecks.random());
  static List<Card> get randomBlade => _getCards(_bladeDecks.random());

  static List<Card> get basic => _getCards(_basic);
  static List<Card> get blade1 => _getCards(_blade_1);
  static List<Card> get blade2 => _getCards(_blade_2);
  static List<Card> get blade3 => _getCards(_blade_3);
}
