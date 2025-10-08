import 'package:samsara/samsara.dart';
import 'package:flutter/material.dart';
import 'package:samsara/components.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
// import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import 'common.dart';

const double _kTextShadowOffset = 0.5;

const List<Shadow> kTextShadow = [
  Shadow(
    // bottomLeft
    offset: Offset(-_kTextShadowOffset, -_kTextShadowOffset),
    color: Colors.black,
    blurRadius: 2.5,
  ),
  Shadow(
    // bottomRight
    offset: Offset(_kTextShadowOffset, -_kTextShadowOffset),
    color: Colors.black,
    blurRadius: 2.5,
  ),
  Shadow(
    // topRight
    offset: Offset(_kTextShadowOffset, _kTextShadowOffset),
    color: Colors.black,
    blurRadius: 2.5,
  ),
  Shadow(
    // topLeft
    offset: Offset(-_kTextShadowOffset, _kTextShadowOffset),
    color: Colors.black,
    blurRadius: 2.5,
  ),
];

abstract class TextStyles {
  static const displayLarge = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 36.0,
  );
  static const displayMedium = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 34.0,
  );
  static const displaySmall = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 32.0,
  );
  static const headlineLarge = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 30.0,
  );
  static const headlineMedium = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 28.0,
  );
  static const headlineSmall = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 26.0,
  );
  static const titleLarge = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 24.0,
  );
  static const titleMedium = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 22.0,
  );
  static const titleSmall = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 20.0,
  );
  static const bodyLarge = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 18.0,
  );
  static const bodyMedium = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 16.0,
  );
  static const bodySmall = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 14.0,
  );
  static const labelLarge = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 12.0,
  );
  static const labelMedium = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 10.0,
  );
  static const labelSmall = TextStyle(
    fontFamily: GameUI.fontFamily,
    fontSize: 8.0,
  );
}

abstract class GameUI {
  static Vector2 size = Vector2.zero();

  static Vector2 get center => size / 2;

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static const hugeIndent = 80.0;
  static const largeIndent = 40.0;
  static const indent = 20.0;
  static const smallIndent = 10.0;
  // general ui
  static const avatarSize = 120.0;
  static const heroInfoHeight = 130.0;
  static const infoButtonSize = Size(30.0, 30.0);

  static const String fontFamily = 'LXGWMONO';
  static const String fontFamily2 = 'RuiZiYunZiKuLiBianTiGBK';

  static const pileZoneIndent = 30.0;
  static const pileZoneMargin = 60.0;

  static const borderColor = Colors.white38;

  static const foregroundColor = Colors.white;
  static const foregroundColorPressed = Colors.white54;
  static final foregroundDiabled = Colors.grey[500];

  static final backgroundColor = Colors.black45;
  static final backgroundColorOpaque = Colors.black;

  static final Paint backgroundPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = backgroundColor3;

  static final backgroundColor2Opaque = Color(0xFF02020F);
  static final backgroundColor2 = Color(0xDD02020F);

  static final backgroundColor3Opaque = Color(0xFF270505);
  static final backgroundColor3 = Color(0xDD270505);

  static final focusedColorOpaque = const Color.fromARGB(255, 0, 32, 64);
  static final focusedColor = Color.fromARGB(255, 0, 32, 64).withAlpha(128);
  static final hoverColorOpaque = Colors.lightBlue;
  static final hoverColor = Colors.lightBlue.withAlpha(128);
  static final selectedColorOpaque = Colors.yellow;
  static final selectedColor = Colors.yellow.withAlpha(128);
  static final outlineColorOpaque = Colors.white;
  static final outlineColor = Colors.white54;

  /// 对话框遮罩背景颜色
  static final barrierColor = Colors.black87;

  static final borderRadius = BorderRadius.circular(5.0);

  static const profileWindowPosition =
      Offset(largeIndent, heroInfoHeight + smallIndent);
  static final profileWindowSize = Vector2(640.0, 480.0);

  static late final Offset detailsWindowPosition;

  static const iconTheme = IconThemeData(
    color: foregroundColor,
  );

  static const textTheme = TextTheme(
    displayLarge: TextStyles.displayLarge,
    displayMedium: TextStyles.displayMedium,
    displaySmall: TextStyles.displaySmall,
    headlineLarge: TextStyles.headlineLarge,
    headlineMedium: TextStyles.headlineMedium,
    headlineSmall: TextStyles.headlineSmall,
    titleLarge: TextStyles.titleLarge,
    titleMedium: TextStyles.titleMedium,
    titleSmall: TextStyles.titleSmall,
    bodyLarge: TextStyles.bodyLarge,
    bodyMedium: TextStyles.bodyMedium,
    bodySmall: TextStyles.bodySmall,
    labelLarge: TextStyles.labelLarge,
    labelMedium: TextStyles.labelMedium,
    labelSmall: TextStyles.labelSmall,
  );

  static final captionStyle = textTheme.labelLarge!;

  static final titleStyle = textTheme.titleLarge!;

  static final darkMaterialTheme = ThemeData(
    splashFactory: NoSplash.splashFactory,
    brightness: Brightness.dark,
    textTheme: textTheme,
    fontFamily: GameUI.fontFamily,
    scaffoldBackgroundColor: Colors.transparent,
    iconTheme: iconTheme,
    dividerColor: foregroundColor,
    colorScheme: ColorScheme.dark(
      surface: backgroundColor2,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: barrierColor,
    ),
    dataTableTheme: DataTableThemeData(
      headingCellCursor: WidgetStatePropertyAll<MouseCursor>(MouseCursor.defer),
      dataRowCursor: WidgetStatePropertyAll<MouseCursor>(MouseCursor.defer),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      toolbarHeight: 36,
      iconTheme: iconTheme,
      actionsIconTheme: iconTheme,
      titleTextStyle: titleStyle,
    ),
    cardTheme: CardThemeData(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        shape: const RoundedRectangleBorder(),
        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: textTheme.bodyMedium,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: foregroundColor,
          ),
          borderRadius: borderRadius,
        ),
        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
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
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: textTheme.bodyMedium,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: backgroundColor2,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: foregroundColor),
        borderRadius: borderRadius,
      ),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(
        fontFamily: GameUI.fontFamily,
        fontSize: 15.0,
      )),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: foregroundColor,
      activeTickMarkColor: foregroundColor,
      thumbColor: foregroundColor,
      valueIndicatorTextStyle: textTheme.bodyMedium,
      showValueIndicator: ShowValueIndicator.never,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: textTheme.bodyMedium,
      unselectedLabelStyle: textTheme.bodyMedium,
    ),
  );

  static final fluentTheme = fluent.FluentThemeData(
    accentColor: fluent.Colors.teal,
    brightness: Brightness.dark,
    fontFamily: GameUI.fontFamily,
    tooltipTheme: fluent.TooltipThemeData(
      textStyle: textTheme.labelSmall,
    ),
    buttonTheme: fluent.ButtonThemeData(
      defaultButtonStyle: fluent.ButtonStyle(
        shape: WidgetStatePropertyAll<ShapeBorder>(
          RoundedRectangleBorder(),
        ),
      ),
      filledButtonStyle: fluent.ButtonStyle(
        backgroundColor: WidgetStateProperty<Color>.fromMap(
          <WidgetStatesConstraint, Color>{
            WidgetState.pressed | WidgetState.focused | WidgetState.selected:
                focusedColor,
            WidgetState.hovered: hoverColor,
            WidgetState.disabled: Colors.transparent,
            WidgetState.any: backgroundColor2,
          },
        ),
        shape: WidgetStatePropertyAll<ShapeBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: foregroundColor),
          ),
        ),
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(
          Colors.white,
        ),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          textTheme.bodyMedium!.copyWith(color: Colors.white),
        ),
      ),
    ),
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
    textStyle: textTheme.titleSmall,
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

  static late Vector2 worldmapBannerSize;

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

  static late Vector2 orderByButtonPosition, filterByButtonPosition;

  /// 卡包展示卡牌的大小
  static late Vector2 cardpackCardSize;

  /// 卡包中1，2，3号卡牌的位置
  static late final List<Vector2> cardpackCardPositions;

  static late Vector2 closeCraftButtonPosition;
  static late Vector2 cardLibraryExpLabelPosition;

  /// 卡牌精炼区域背景大小
  static late Vector2 cardCraftingZoneSize;

  /// 卡牌精炼区域初始位置在游戏场景外
  static late Vector2 cardCraftingZoneInitialPosition;

  /// 打开精炼功能后的卡牌精炼区域
  static late Vector2 cardCraftingZonePosition;

  static final Vector2 skillBookSize = Vector2(360, 360);
  static final Vector2 expBottleSize = Vector2(135, 180);
  static late Vector2 skillBookPosition, expBottlePosition;

  // battle ui
  static late Vector2 battleCardSize;
  static late Vector2 battleCardFocusedSize;
  static late Vector2 battleDeckZoneSize;
  static late Vector2 p1BattleDeckZonePosition;
  static late Vector2 p2BattleDeckZonePosition;
  static late Vector2 p1CharacterAnimationPosition;
  static late Vector2 p2CharacterAnimationPosition;

  static late Vector2 versusBannerSize;
  static late Vector2 versusIconSize;
  static late Vector2 battleCharacterAvatarSize;
  static final Vector2 equipmentsBarSize =
      Vector2(32 * (kEquipmentMax + 2), 30);

  static late Vector2 battleCardFocusedOffset;

  static final heroSpriteSize = Vector2(80.0 * 2, 112.0 * 2);
  static final statusEffectIconSize = Vector2(24, 24);
  static final permanentStatusEffectIconSize = Vector2(48, 48);
  static const resourceBarHeight = 10.0;

  // cultivation ui
  static late Vector2 cultivatorPosition;
  static late Vector2 condensedPosition;
  static late Vector2 expBarPosition;
  static late Vector2 levelDescriptionPosition;
  static final cultivatorSize = Vector2(200, 200);
  static final cultivationRankButton = Vector2(80, 80);
  static final maxCondenseSize = Vector2(250, 250);
  static final levelDescriptionSize = Vector2(500, 50);
  static final expBarSize = Vector2(600, 25);

  static late Vector2 levelUpButtonPosition;
  static late Vector2 collectButtonPosition;
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

    Hovertip.backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Hovertip.defaultContentConfig = Hovertip.defaultContentConfig.copyWith(
    //   textStyle: TextStyle(fontFamily: GameUI.fontFamily),
    // );

    GameUI.size = size;

    SpriteButton.defaultTextConfig = spriteButtonTextConfig;

    Hovertip.defaultContentConfig = hovertipContentConfig;

    FadingText.defaultTextStyle = fadingTextStyle;

    detailsWindowPosition = Offset(
        size.x - profileWindowSize.x - largeIndent, profileWindowPosition.dy);

    worldmapBannerSize = Vector2(640.0, 160.0);

    libraryZonePosition = Vector2((120 / 1440 * size.x).roundToDouble(),
        (180 / 810 * size.y).roundToDouble());
    libraryZoneSize = Vector2((960 / 1440 * size.x).roundToDouble(),
        (450 / 810 * size.y).roundToDouble());

    libraryZoneBackgroundPosition = Vector2(0, libraryZonePosition.y);
    libraryZoneBackgroundSize = Vector2((1190 / 1440 * size.x).roundToDouble(),
        (libraryZoneSize.y).roundToDouble());

    orderByButtonPosition = libraryZonePosition + Vector2(50, -50);
    filterByButtonPosition =
        orderByButtonPosition + Vector2(buttonSizeLong.x + largeIndent, 0);

    decksZoneBackgroundSize = Vector2(
        size.x - libraryZoneBackgroundSize.x, libraryZoneBackgroundSize.y);
    decksZoneBackgroundPosition =
        Vector2(libraryZoneBackgroundSize.x, libraryZoneBackgroundPosition.y);

    final deckbuildingCardWidth = ((130 / 1440 * size.x).roundToDouble());
    final deckbuildingCardHeight =
        (deckbuildingCardWidth * 1.351351).roundToDouble();
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

    final libraryCardWidth = libraryZoneSize.x / 5 - indent;
    final libraryCardHeight = libraryCardWidth * cardSizeRatio;
    libraryCardSize = Vector2(libraryCardWidth, libraryCardHeight);
    // libraryCardSize = deckbuildingCardSize;

    cardpackCardSize = libraryCardSize * 1.5;

    final position2 = Vector2(
      size.x / 2 - cardpackCardSize.x / 2,
      135.0,
    );

    final position1 = position2 - Vector2(cardpackCardSize.x + hugeIndent, 0);

    final position3 = position2 + Vector2(cardpackCardSize.x + hugeIndent, 0);

    cardpackCardPositions = [position1, position2, position3];

    closeCraftButtonPosition =
        Vector2(size.x / 2, size.y - largeIndent - buttonSizeMedium.y / 2);

    cardLibraryExpLabelPosition = Vector2(size.x / 2, size.y - 50);

    cardCraftingZoneSize = Vector2((270 / 1440 * size.x).roundToDouble(),
        (270 / 810 * size.y).roundToDouble());

    cardCraftingZoneInitialPosition =
        Vector2(decksZoneBackgroundPosition.x, -150.0);

    cardCraftingZonePosition = decksZoneBackgroundPosition - Vector2(0, 100);

    skillBookPosition = Vector2(-60, GameUI.size.y - 160);
    // expBottlePosition = Vector2(size.x / 2, size.y - expBottleSize.y * 0.33);
    expBottlePosition = Vector2(
        skillBookPosition.x + skillBookSize.x + largeIndent,
        GameUI.size.y - expBottleSize.y * 0.33);

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
    //         permanentStatusEffectIconSize.y -
    //         battleCardFocusedSize.y -
    //         indent);

    // p2BattleCardFocusedPosition = Vector2(
    //     size.x - indent - battleCardFocusedSize.x,
    //     p2BattleDeckZonePosition.y -
    //         indent -
    //         permanentStatusEffectIconSize.y -
    //         battleCardFocusedSize.y -
    //         indent);

    battleCardFocusedOffset = Vector2(
        -(battleCardFocusedSize.x - battleCardSize.x) / 2,
        -(battleCardFocusedSize.y - battleCardSize.y));

    p1CharacterAnimationPosition = Vector2(
      size.x / 2 - 208,
      p1BattleDeckZonePosition.y - heroSpriteSize.y,
    );

    p2CharacterAnimationPosition = Vector2(
      size.x / 2 + 208,
      p2BattleDeckZonePosition.y - heroSpriteSize.y,
    );

    versusBannerSize = Vector2(520.0, 180.0);
    versusIconSize = Vector2(160.0, 180.0);
    battleCharacterAvatarSize = Vector2(100.0, 100.0);

    final siteCardWidth = (size.x - 300) / 8 - indent;
    final siteCardHeight = (siteCardWidth * 1.714).roundToDouble();

    siteCardSize = Vector2(siteCardWidth, siteCardHeight);

    siteCardFocusedSize = siteCardSize * 1.2;

    siteListPosition = Vector2(indent, size.y - indent - siteCardSize.y);

    siteExitCardPositon =
        Vector2(size.x - indent - siteCardSize.x, siteListPosition.y + 10);

    cultivatorPosition = Vector2(center.x, center.y);

    condensedPosition = Vector2(center.x, center.y + 40.0);

    expBarPosition = Vector2(center.x, center.y + 300.0);

    levelDescriptionPosition =
        Vector2(center.x, expBarPosition.y - levelDescriptionSize.y);

    levelUpButtonPosition = Vector2(
        center.x + buttonSizeMedium.x / 2 + indent, expBarPosition.y + 50);
    collectButtonPosition = Vector2(
        center.x - buttonSizeMedium.x / 2 - indent, levelUpButtonPosition.y);

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
