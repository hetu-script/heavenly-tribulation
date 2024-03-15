import 'package:vector_math/vector_math_64.dart';

abstract class GameUI {
  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static late double indent;

  static Vector2? size;

  static const avatarSize = 120.0;
  static const heroInfoHeight = 130.0;
  static const npcListArrowHeight = 25.0;

  // the ratio of the illustration height relative to the card height
  static late double cardIllustrationHeightRatio;

  // deckbuilding ui
  static late Vector2 libraryCardSize,
      deckbuildingCardSize,
      deckbuildingZoneSize,
      deckbuildingZonePileOffset,
      librarySize,
      libraryPosition;

  static late Vector2 battleCardSize,
      battleCardFocusedSize,
      battleDeckZoneSize,
      p1BattleDeckZonePosition,
      p2BattleDeckZonePosition,
      p1BattleCardFocusedPosition,
      p2BattleCardFocusedPosition,
      heroSpriteSize,
      p1HeroSpritePosition,
      p2HeroSpritePosition;

  static late Vector2 statusEffectIconSize, permenantStatusEffectIconSize;

  static late double resourceBarHeight;

  static late Vector2 siteCardSize,
      siteCardFocusedSize,
      siteListPosition,
      siteExitCardPositon;

  static void init(Vector2 size) {
    if (GameUI.size == size) return;

    GameUI.size = size;

    indent = 20.0;
    cardIllustrationHeightRatio = 0.592;

    final libraryCardWidth = size.x / 6 - indent * 2;
    final libraryCardHeight = libraryCardWidth * 1.382;
    libraryCardSize = Vector2(libraryCardWidth, libraryCardHeight);

    final deckbuildingCardWidth = (size.x - 300) / 8 - indent;
    final deckbuildingCardHeight = deckbuildingCardWidth * 1.382;

    deckbuildingCardSize =
        Vector2(deckbuildingCardWidth, deckbuildingCardHeight);

    deckbuildingZoneSize = Vector2(size.x, deckbuildingCardHeight + indent * 4);
    deckbuildingZonePileOffset = Vector2(deckbuildingCardWidth + indent, 0);

    librarySize = Vector2(size.x, size.y - deckbuildingZoneSize.y);
    libraryPosition = Vector2(0, deckbuildingZoneSize.y);

    battleCardSize = deckbuildingCardSize;
    battleDeckZoneSize =
        Vector2(size.x / 2 - indent * 2, battleCardSize.y + indent);

    battleCardFocusedSize = libraryCardSize;

    p1BattleDeckZonePosition =
        Vector2(indent / 2, size.y - battleDeckZoneSize.y - indent / 2);
    p2BattleDeckZonePosition = Vector2(
        size.x - battleDeckZoneSize.x - indent / 2, p1BattleDeckZonePosition.y);

    statusEffectIconSize = Vector2(24, 24);
    permenantStatusEffectIconSize = Vector2(48, 48);
    resourceBarHeight = 10.0;

    p1BattleCardFocusedPosition = Vector2(
        indent,
        p1BattleDeckZonePosition.y -
            indent -
            permenantStatusEffectIconSize.y -
            battleCardFocusedSize.y -
            indent);

    p2BattleCardFocusedPosition = Vector2(
        size.x - indent - battleCardFocusedSize.x,
        p2BattleDeckZonePosition.y -
            indent -
            permenantStatusEffectIconSize.y -
            battleCardFocusedSize.y -
            indent);

    heroSpriteSize = Vector2(80.0 * 2, 112.0 * 2);

    p1HeroSpritePosition = Vector2(
      size.x / 2 - 208,
      p1BattleDeckZonePosition.y - heroSpriteSize.y,
    );

    p2HeroSpritePosition = Vector2(
      size.x / 2 + 208,
      p2BattleDeckZonePosition.y - heroSpriteSize.y,
    );

    final siteCardWidth = (size.x - 300) / 8 - indent;
    final siteCardHeight = siteCardWidth * 1.714;

    siteCardSize = Vector2(siteCardWidth, siteCardHeight);

    siteCardFocusedSize = siteCardSize * 1.2;

    siteListPosition = Vector2(indent, size.y - indent - siteCardSize.y);

    siteExitCardPositon =
        Vector2(size.x - indent - siteCardSize.x, siteListPosition.y + 10);

    _isInitted = true;
  }
}
