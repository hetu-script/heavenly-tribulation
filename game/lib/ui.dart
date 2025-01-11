import 'package:samsara/samsara.dart';
import 'package:flutter/material.dart';
import 'package:samsara/components.dart';
// import 'package:samsara/components/hovertip.dart';

abstract class GameUI {
  static Vector2 size = Vector2.zero();

  static Vector2 get center => size / 2;

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static const largeIndent = 40.0;
  static const indent = 20.0;
  static const smallIndent = 10.0;
  // general ui
  static const avatarSize = 120.0;
  static const heroInfoHeight = 130.0;
  static const infoButtonSize = Size(30.0, 30.0);

  static const String fontFamily = 'RuiZiYunZiKuLiBianTiGBK';
  static const String fontFamily2 = 'NotoSansMono';

  static const pileZoneIndent = 30.0;
  static const pileZoneMargin = 60.0;

  static const foregroundColor = Colors.white;
  static final backgroundColor = Colors.black.withAlpha(220);
  static final barrierColor = Colors.black.withAlpha(128);
  static final borderRadius = BorderRadius.circular(5.0);

  static const profileWindowPosition =
      Offset(largeIndent, heroInfoHeight + smallIndent);
  static const profileWindowWidth = 640.0;

  static final Vector2 historyPanelSize = Vector2(328, 140);

  static final detailsWindowPosition = Offset(
      profileWindowPosition.dx + profileWindowWidth + largeIndent,
      profileWindowPosition.dy);

  static const iconTheme = IconThemeData(
    color: foregroundColor,
  );

  static const captionStyle = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 18.0,
  );

  static const textTheme = TextTheme(
    titleMedium: TextStyle(
      fontFamily: GameUI.fontFamily,
      fontSize: 24.0,
    ),
    bodySmall: TextStyle(
      fontFamily: GameUI.fontFamily2,
      fontSize: 14.0,
    ),
    bodyMedium: TextStyle(
      fontFamily: GameUI.fontFamily,
      fontSize: 16.0,
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    textTheme: textTheme,
    fontFamily: GameUI.fontFamily,
    colorScheme: ColorScheme.dark(
      surface: backgroundColor,
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
    dialogBackgroundColor: barrierColor,
    iconTheme: iconTheme,
    cardTheme: CardTheme(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        shape: const RoundedRectangleBorder(),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: foregroundColor,
          ),
          borderRadius: borderRadius,
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
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: foregroundColor),
        borderRadius: borderRadius,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: foregroundColor,
      activeTickMarkColor: foregroundColor,
      thumbColor: foregroundColor,
      valueIndicatorTextStyle: textTheme.bodyMedium,
    ),
    dividerColor: foregroundColor,
  );

  static final spriteButtonTextConfig = ScreenTextConfig(
    anchor: Anchor.center,
    textStyle: textTheme.bodyMedium,
    outlined: true,
  );

  static final hovertipContentConfig = ScreenTextConfig(
    anchor: Anchor.topLeft,
    padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
    overflow: ScreenTextOverflow.wordwrap,
    textStyle: textTheme.bodyMedium,
  );

  static const fadingTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static final siteTitleConfig = ScreenTextConfig(
    outlined: true,
    padding: EdgeInsets.only(top: 10),
    anchor: Anchor.topCenter,
    textStyle: textTheme.titleMedium,
  );

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

  // ratio = height / width
  static const cardSizeRatio = 1.382;

  // deckbuilding ui
  static late Vector2 libraryCardSize;
  static late Vector2 deckbuildingCardSize;
  // static late Vector2    // deckCoverSize;
  static late Vector2 deckbuildingZonePileOffset;
  // static late Vector2    // deckbuildingZoneSize;
  static late Vector2 decksZoneBackgroundSize;
  static late Vector2 decksZoneBackgroundPosition;
  static late Vector2 decksZoneCloseButtonPosition;
  static late Vector2 setBattleDeckButtonPosition;
  // static late Vector2    // deckCoverPosition;
  // static late Vector2    // deckPileInitialPosition;

  /// 卡牌库背景区域位置，指背景图的位置，大于实际的卡牌排列可用区域。
  static late Vector2 libraryZoneBackgroundPosition;

  /// 卡牌库背景区域大小
  static late Vector2 libraryZoneBackgroundSize;

  /// 卡牌库区域位置
  static late Vector2 libraryZonePosition;

  /// 卡牌库区域大小，这里是实际的卡牌排列可用区域，小于卡牌库背景区域
  static late Vector2 libraryZoneSize;

  /// 卡牌精炼区域背景大小
  static late Vector2 cardCraftingZoneSize;

  /// 卡牌精炼区域初始位置在游戏场景外
  static late Vector2 cardCraftingZoneInitialPosition;

  /// 打开精炼功能后的卡牌精炼区域
  static late Vector2 cardCraftingZonePosition;

  // battle ui
  static late Vector2 battleCardSize;
  static late Vector2 battleCardFocusedSize;
  static late Vector2 battleDeckZoneSize;
  static late Vector2 p1BattleDeckZonePosition;
  static late Vector2 p2BattleDeckZonePosition;
  //  static late Vector2    // p1BattleCardFocusedPosition;
  //  static late Vector2    // p2BattleCardFocusedPosition;
  static late Vector2 p1HeroSpritePosition;
  static late Vector2 p2HeroSpritePosition;

  static late Vector2 battleCardFocusedOffset;

  static final heroSpriteSize = Vector2(80.0 * 2, 112.0 * 2);
  static final statusEffectIconSize = Vector2(24, 24);
  static final permenantStatusEffectIconSize = Vector2(48, 48);
  static const resourceBarHeight = 10.0;

  // cultivation ui
  static late Vector2 cultivatorPosition;
  static late Vector2 condensedPosition;
  static late Vector2 expBarPosition;
  static late Vector2 levelDescriptionPosition;
  static final cultivatorSize = Vector2(200, 200);
  static final cultivationRankButton = Vector2(80, 80);
  static final maxCondenseSize = Vector2(250, 250);
  static final levelDescriptionSize = Vector2(300, 25);
  static final expBarSize = Vector2(600, 25);

  // static late Vector2 cardLibraryButtonPosition,
  // static late Vector2 cardPacksButtonPosition,
  static late Vector2 expCollectionPageButtonPosition;
  // static late Vector2 introspectionButtonPosition;
  static late Vector2 talentTreePageButtonPosition;
  // static final cardLibraryButtonSize = Vector2(120, 120);
  // static final cardPacksButtonSize = Vector2(120, 120);
  static final buttonSizeSmall = Vector2(90, 28);
  static final buttonSizeMedium = Vector2(140, 40);
  static final buttonSizeLarge = Vector2(240, 75);
  static final buttonSizeSquare = Vector2(40, 40);
  static final buttonSizeLong = Vector2(180, 40);

  static final cultivationRankButtonSize = Vector2(120, 120);

  // // talent tree ui
  static final skillButtonSizeSmall = Vector2(40, 40);
  static final skillButtonSizeMedium = Vector2(60, 60);
  static final skillButtonSizeLarge = Vector2(80, 80);

  static void resizeTo(Vector2 size) {
    if (GameUI.size == size) return;

    // Hovertip.defaultContentConfig = Hovertip.defaultContentConfig.copyWith(
    //   textStyle: TextStyle(fontFamily: GameUI.fontFamily),
    // );

    GameUI.size = size;

    SpriteButton.defaultTextConfig = spriteButtonTextConfig;

    Hovertip.defaultContentConfig = hovertipContentConfig;

    FadingText.defaultTextStyle = fadingTextStyle;

    libraryZonePosition = Vector2(120 / 1440 * size.x, 180 / 810 * size.y);
    libraryZoneSize = Vector2(960 / 1440 * size.x, 450 / 810 * size.y);

    libraryZoneBackgroundPosition = Vector2(0, libraryZonePosition.y);
    libraryZoneBackgroundSize =
        Vector2(1190 / 1440 * size.x, libraryZoneSize.y);

    decksZoneBackgroundSize = Vector2(
        size.x - libraryZoneBackgroundSize.x, libraryZoneBackgroundSize.y);
    decksZoneBackgroundPosition =
        Vector2(libraryZoneBackgroundSize.x, libraryZoneBackgroundPosition.y);

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

    setBattleDeckButtonPosition = Vector2(
      decksZoneBackgroundPosition.x + smallIndent,
      decksZoneBackgroundPosition.y + decksZoneBackgroundSize.y,
    );

    decksZoneCloseButtonPosition = Vector2(
      setBattleDeckButtonPosition.x,
      setBattleDeckButtonPosition.y + buttonSizeMedium.y + indent,
    );

    // deckbuildingZoneSize = Vector2(size.x, deckbuildingCardHeight + indent * 4);
    deckbuildingZonePileOffset = Vector2(0, 30);

    // final libraryCardWidth = size.x / 6 - largeIndent;
    // final libraryCardHeight = libraryCardWidth * cardSizeRatio;
    // libraryCardSize = Vector2(libraryCardWidth, libraryCardHeight);
    libraryCardSize = deckbuildingCardSize;

    cardCraftingZoneSize = Vector2(270 / 1440 * size.x, 270 / 810 * size.y);

    cardCraftingZoneInitialPosition =
        Vector2(decksZoneBackgroundPosition.x, -150.0);

    cardCraftingZonePosition = decksZoneBackgroundPosition - Vector2(0, 100);

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

Rect getRenderRect(BuildContext context) {
  final renderBox = context.findRenderObject() as RenderBox;
  final Size size = renderBox.size;
  final Offset offset = renderBox.localToGlobal(Offset.zero);
  final Rect rect =
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

  return rect;
}
