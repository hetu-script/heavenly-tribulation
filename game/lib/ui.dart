import 'package:samsara/samsara.dart';
import 'package:flutter/material.dart';

const kForegroundColor = Colors.white;
final kBackgroundColor = Colors.black.withAlpha(180);
final kBarrierColor = Colors.black.withAlpha(128);
final kBorderRadius = BorderRadius.circular(5.0);

const iconTheme = IconThemeData(
  color: kForegroundColor,
);

const captionStyle = TextStyle(
  fontFamily: GameUI.fontFamily,
  fontSize: 18.0,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  textTheme: TextTheme(),
  fontFamily: GameUI.fontFamily,
  colorScheme: ColorScheme.dark(
    surface: kBackgroundColor,
  ),
  scaffoldBackgroundColor: Colors.transparent,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    color: Colors.transparent,
    toolbarHeight: 36,
    iconTheme: iconTheme,
    actionsIconTheme: iconTheme,
    titleTextStyle: captionStyle,
  ),
  dialogBackgroundColor: kBarrierColor,
  iconTheme: iconTheme,
  cardTheme: CardTheme(
    elevation: 0.5,
    shape: RoundedRectangleBorder(
      borderRadius: kBorderRadius,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kForegroundColor,
      shape: const RoundedRectangleBorder(),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kBackgroundColor,
      foregroundColor: kForegroundColor,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: kForegroundColor,
        ),
        borderRadius: kBorderRadius,
      ),
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: SegmentedButton.styleFrom(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5.0),
          topRight: Radius.circular(5.0),
        ),
      ),
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: kBackgroundColor,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: kForegroundColor),
      borderRadius: kBorderRadius,
    ),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: kForegroundColor,
    activeTickMarkColor: kForegroundColor,
    thumbColor: kForegroundColor,
    valueIndicatorTextStyle: TextStyle(
      fontFamily: GameUI.fontFamily,
      color: kForegroundColor,
    ),
  ),
  dividerColor: kForegroundColor,
);

abstract class GameUI {
  static const String fontFamily = 'RuiZiYunZiKuLiBianTiGBK';

  static const ScreenTextConfig siteTitleConfig = ScreenTextConfig(
    outlined: true,
    padding: EdgeInsets.only(top: 10),
    anchor: Anchor.topCenter,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 24.0,
      fontFamily: GameUI.fontFamily,
    ),
  );

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static const largeIndent = 40.0;
  static const indent = 20.0;
  static const smallIndent = 10.0;
  static const pileZoneIndent = 30.0;
  static const pileZoneMargin = 60.0;

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
      // deckCoverSize,
      deckbuildingZonePileOffset,
      // deckbuildingZoneSize,
      decksZoneBackgroundSize,
      decksZoneBackgroundPosition,
      decksZoneCloseButtonPosition,
      // deckCoverPosition,
      // deckPileInitialPosition,
      libraryZoneBackgroundSize,
      libraryZoneBackgroundPosition,
      libraryZoneSize,
      libraryZonePosition;

  // battle ui
  static late Vector2 battleCardSize,
      battleCardFocusedSize,
      battleDeckZoneSize,
      p1BattleDeckZonePosition,
      p2BattleDeckZonePosition,
      // p1BattleCardFocusedPosition,
      // p2BattleCardFocusedPosition,
      p1HeroSpritePosition,
      p2HeroSpritePosition;

  static late Vector2 battleCardFocusedOffset;

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
  static final cultivationRankButton = Vector2(80, 80);
  static final maxCondenseSize = Vector2(250, 250);
  static final levelDescriptionSize = Vector2(300, 25);
  static final expBarSize = Vector2(600, 25);

  static late Vector2
      // cardLibraryButtonPosition,
      //     cardPacksButtonPosition,
      expCollectionPageButtonPosition,
      // introspectionButtonPosition,
      talentTreePageButtonPosition;
  // static final cardLibraryButtonSize = Vector2(120, 120);
  // static final cardPacksButtonSize = Vector2(120, 120);
  static final buttonSizeMedium = Vector2(140, 40);

  static final cultivationRankButtonSize = Vector2(120, 120);

  // // talent tree ui
  static final skillButtonSizeSmall = Vector2(40, 40);
  static final skillButtonSizeMedium = Vector2(60, 60);
  static final skillButtonSizeLarge = Vector2(80, 80);

  static void init(Vector2 size) {
    if (GameUI.size == size) return;

    GameUI.size = size;

    libraryZonePosition = Vector2(120 / 1440 * size.x, 180 / 810 * size.y);
    libraryZoneSize = Vector2(960 / 1440 * size.x, 450 / 810 * size.y);

    libraryZoneBackgroundPosition = Vector2(0, libraryZonePosition.y);
    libraryZoneBackgroundSize =
        Vector2(1190 / 1440 * size.x, libraryZoneSize.y);

    decksZoneBackgroundSize = Vector2(
        size.x - libraryZoneBackgroundSize.x, libraryZoneBackgroundSize.y);
    decksZoneBackgroundPosition =
        Vector2(libraryZoneBackgroundSize.x, libraryZonePosition.y);

    final deckbuildingCardWidth = (170 / 270 * decksZoneBackgroundSize.x);
    final deckbuildingCardHeight = deckbuildingCardWidth * 1.382;
    deckbuildingCardSize =
        Vector2(deckbuildingCardWidth, deckbuildingCardHeight);

    // final deckCoverWidth = deckbuildingCardWidth * 1.2166;
    // final deckCoverHeight = deckbuildingCardHeight * 1.0612;
    // deckCoverSize = Vector2(deckCoverWidth, deckCoverHeight);

    // deckPileInitialPosition =
    //     Vector2(decksZoneBackgroundPosition.x, decksZoneBackgroundPosition.y);

    // deckCoverPosition =
    //     Vector2(decksZoneBackgroundPosition.x, decksZoneBackgroundPosition.y);

    decksZoneCloseButtonPosition = Vector2(
        decksZoneBackgroundPosition.x + indent,
        size.y - largeIndent - buttonSizeMedium.y);

    // deckbuildingZoneSize = Vector2(size.x, deckbuildingCardHeight + indent * 4);
    deckbuildingZonePileOffset = Vector2(0, 30);

    // final libraryCardWidth = size.x / 6 - largeIndent;
    // final libraryCardHeight = libraryCardWidth * cardSizeRatio;
    // libraryCardSize = Vector2(libraryCardWidth, libraryCardHeight);
    libraryCardSize = deckbuildingCardSize;

    battleCardSize = deckbuildingCardSize;
    battleDeckZoneSize =
        Vector2(size.x / 2 - largeIndent, battleCardSize.y + indent);

    battleCardFocusedSize =
        Vector2(battleCardSize.x + largeIndent, battleCardSize.y + largeIndent);

    p1BattleDeckZonePosition =
        Vector2(indent / 2, size.y - battleDeckZoneSize.y - indent / 2);
    p2BattleDeckZonePosition = Vector2(
        size.x - battleDeckZoneSize.x - indent / 2, p1BattleDeckZonePosition.y);

    // p1BattleCardFocusedPosition = Vector2(
    //     indent,
    //     p1BattleDeckZonePosition.y -
    //         indent -
    //         permenantStatusEffectIconSize.y -
    //         battleCardFocusedSize.y -
    //         indent);

    // p2BattleCardFocusedPosition = Vector2(
    //     size.x - indent - battleCardFocusedSize.x,
    //     p2BattleDeckZonePosition.y -
    //         indent -
    //         permenantStatusEffectIconSize.y -
    //         battleCardFocusedSize.y -
    //         indent);

    battleCardFocusedOffset = Vector2(
        -(battleCardFocusedSize.x - battleCardSize.x) / 2,
        -(battleCardFocusedSize.y - battleCardSize.y));

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

    condensedPosition = Vector2(center.x, center.y + 40.0);

    expBarPosition = Vector2(center.x, center.y + 300.0);

    levelDescriptionPosition =
        Vector2(center.x, expBarPosition.y - expBarSize.y - indent);

    expCollectionPageButtonPosition = Vector2(center.x, expBarPosition.y + 50);
    // meditateButtonPosition =
    //     Vector2(center.x - 70 - smallIndent, expBarPosition.y - 50);
    // introspectionButtonPosition =
    //     Vector2(center.x - 140 - indent, meditateButtonPosition.y);
    // enlightenmentButtonPosition =
    //     Vector2(center.x + 70 + smallIndent, meditateButtonPosition.y);
    talentTreePageButtonPosition = expCollectionPageButtonPosition;

    // cardLibraryButtonPosition = Vector2(
    //     size.x - indent - cardLibraryButtonSize.x / 2,
    //     size.y - indent - cardLibraryButtonSize.y / 2);

    // cardPacksButtonPosition = Vector2(
    //     cardLibraryButtonPosition.x -
    //         cardLibraryButtonSize.x / 2 -
    //         smallIndent -
    //         cardPacksButtonSize.x / 2,
    //     cardLibraryButtonPosition.y);

    _isInitted = true;
  }
}

Rect getWidgetRenderRect(GlobalKey key) {
  final renderBox = key.currentContext!.findRenderObject() as RenderBox;
  final Size size = renderBox.size;
  final Offset offset = renderBox.localToGlobal(Offset.zero);
  final Rect rect =
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

  return rect;
}
