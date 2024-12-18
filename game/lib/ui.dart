import 'package:samsara/samsara.dart';

abstract class GameUI {
  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static const indent = 20.0;
  static const smallIndent = 10.0;

  static Vector2 size = Vector2.zero();

  static Vector2 get center => size / 2;

  // general ui
  static const avatarSize = 120.0;
  static const heroInfoHeight = 130.0;
  static final Vector2 historyPanelSize = Vector2(328, 140);

  // location site scene ui
  static late Vector2 siteCardSize,
      siteCardFocusedSize,
      siteListPosition,
      siteExitCardPositon;
  static const npcListArrowHeight = 25.0;

  // the relative paddings of the illustration rect
  static const cardIllustrationRelativePaddings =
      Rect.fromLTRB(0.06, 0.04, 0.06, 0.42);

  static final battleCardPreferredSize = Vector2(250, 250 * 1.382);

  static const battleCardTitlePaddings = EdgeInsets.fromLTRB(0, 0.585, 0, 0);

  static final ScreenTextConfig battleCardTitleStyle = const ScreenTextConfig(
        anchor: Anchor.topCenter,
        outlined: true,
        textStyle: TextStyle(fontSize: 18.0),
      ),
      battleCardDescriptionStyle = ScreenTextConfig(
        anchor: Anchor.center,
        outlined: true,
      ),
      battleCardStackStyle = const ScreenTextConfig(
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
        anchor: Anchor.bottomCenter,
        padding: EdgeInsets.only(bottom: -20),
        outlined: true,
      );

  // ratio = height / width
  static const cardSizeRatio = 1.382;

  // deckbuilding ui
  static late Vector2 libraryCardSize,
      deckbuildingCardSize,
      deckbuildingZoneSize,
      deckbuildingZonePileOffset,
      libraryZoneSize,
      libraryZonePosition;

  // battle ui
  static late Vector2 battleCardSize,
      battleCardFocusedSize,
      battleDeckZoneSize,
      p1BattleDeckZonePosition,
      p2BattleDeckZonePosition,
      p1BattleCardFocusedPosition,
      p2BattleCardFocusedPosition,
      p1HeroSpritePosition,
      p2HeroSpritePosition;
  static final heroSpriteSize = Vector2(80.0 * 2, 112.0 * 2);
  static final statusEffectIconSize = Vector2(24, 24);
  static final permenantStatusEffectIconSize = Vector2(48, 48);
  static const resourceBarHeight = 10.0;

  // cultivation ui
  static late Vector2 cultivatorPosition,
      condensedPosition,
      expBarPosition,
      levelDescriptionPosition;
  static final cultivatorSize = Vector2(200, 200);
  static final maxCondenseSize = Vector2(250, 250);
  static final expBarSize = Vector2(600, 25);

  static late Vector2 cardLibraryButtonPosition,
      cardPacksButtonPosition,
      meditateButtonPosition,
      // introspectionButtonPosition,
      enlightenmentButtonPosition;
  static final cardLibraryButtonSize = Vector2(120, 120);
  static final cardPacksButtonSize = Vector2(120, 120);
  static final stateButtonSize = Vector2(140, 40);

  static final cultivationRankButtonSize = Vector2(120, 120);

  // talent tree ui
  static final talentTreeButtonSizeS = Vector2(40, 40);
  static final talentTreeButtonSizeM = Vector2(60, 60);
  static final talentTreeButtonSizeL = Vector2(80, 80);

  static void init(Vector2 size) {
    if (GameUI.size == size) return;

    GameUI.size = size;

    final deckbuildingCardWidth = (size.x - 300) / 8 - indent;
    final deckbuildingCardHeight = deckbuildingCardWidth * 1.382;
    deckbuildingCardSize =
        Vector2(deckbuildingCardWidth, deckbuildingCardHeight);

    deckbuildingZoneSize = Vector2(size.x, deckbuildingCardHeight + indent * 4);
    deckbuildingZonePileOffset = Vector2(deckbuildingCardWidth + indent, 0);

    // final libraryCardWidth = size.x / 6 - indent * 2;
    // final libraryCardHeight = libraryCardWidth * cardSizeRatio;
    // libraryCardSize = Vector2(libraryCardWidth, libraryCardHeight);
    libraryCardSize = deckbuildingCardSize;

    libraryZoneSize = Vector2(size.x, size.y - deckbuildingZoneSize.y);
    libraryZonePosition = Vector2(0, deckbuildingZoneSize.y);

    battleCardSize = deckbuildingCardSize;
    battleDeckZoneSize =
        Vector2(size.x / 2 - indent * 2, battleCardSize.y + indent);

    battleCardFocusedSize = libraryCardSize;

    p1BattleDeckZonePosition =
        Vector2(indent / 2, size.y - battleDeckZoneSize.y - indent / 2);
    p2BattleDeckZonePosition = Vector2(
        size.x - battleDeckZoneSize.x - indent / 2, p1BattleDeckZonePosition.y);

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

    cultivatorPosition = Vector2(center.x, center.y);

    condensedPosition = Vector2(center.x, center.y + 20.0);

    expBarPosition = Vector2(center.x, center.y + 350.0);

    levelDescriptionPosition =
        Vector2(center.x, expBarPosition.y + expBarSize.y + indent);

    meditateButtonPosition =
        Vector2(center.x - 70 - smallIndent, expBarPosition.y - 50);
    // introspectionButtonPosition =
    //     Vector2(center.x - 140 - indent, meditateButtonPosition.y);
    enlightenmentButtonPosition =
        Vector2(center.x + 70 + smallIndent, meditateButtonPosition.y);

    cardLibraryButtonPosition = Vector2(
        size.x - indent - cardLibraryButtonSize.x / 2, expBarPosition.y);

    cardPacksButtonPosition = Vector2(
        size.x -
            indent -
            cardLibraryButtonSize.x -
            smallIndent -
            cardPacksButtonSize.x / 2,
        expBarPosition.y);

    _isInitted = true;
  }
}
