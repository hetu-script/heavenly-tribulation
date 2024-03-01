import 'package:vector_math/vector_math_64.dart';

abstract class GameUI {
  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static late double indent;

  static Vector2? size;
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
      battleCardFocusedBSize,
      battleDeckZoneSize,
      p1BattleDeckZonePosition,
      p2BattleDeckZonePosition,
      p1BattleCardFocusedPosition,
      p2BattleCardFocusedPosition,
      heroSpriteSize,
      p1HeroSpritePosition,
      p2HeroSpritePosition;

  static void init(Vector2 size) {
    if (GameUI.size == size) return;

    GameUI.size = size;

    indent = 20.0;
    cardIllustrationHeightRatio = 0.592;

    final libraryCardWidth = size.x / 6 - indent * 2;
    final libraryCardHeight = libraryCardWidth * 1.382;
    libraryCardSize = Vector2(libraryCardWidth, libraryCardHeight);

    final deckbuildingCardWidth = (1440.0 - 300) / 8 - indent;
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

    battleCardFocusedBSize = libraryCardSize;

    p1BattleDeckZonePosition =
        Vector2(indent / 2, size.y - battleDeckZoneSize.y - indent / 2);
    p2BattleDeckZonePosition = Vector2(
        size.x - battleDeckZoneSize.x - indent / 2, p1BattleDeckZonePosition.y);

    p1BattleCardFocusedPosition = Vector2(
        indent, p1BattleDeckZonePosition.y - indent - battleCardFocusedBSize.y);

    p2BattleCardFocusedPosition = Vector2(
        size.x - indent - battleCardFocusedBSize.x,
        p2BattleDeckZonePosition.y - indent - battleCardFocusedBSize.y);

    heroSpriteSize = Vector2(80.0 * 2, 112.0 * 2);

    p1HeroSpritePosition = Vector2(
      size.x / 2 - 208,
      p1BattleDeckZonePosition.y - heroSpriteSize.y,
    );

    p2HeroSpritePosition = Vector2(
      size.x / 2 + 208,
      p2BattleDeckZonePosition.y - heroSpriteSize.y,
    );

    _isInitted = true;
  }
}
