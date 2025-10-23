import 'package:samsara/samsara.dart';
import 'package:flutter/material.dart';
import 'package:samsara/components.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
// import 'package:samsara/colors.dart';

import 'data/common.dart';
import 'engine.dart';
import 'widgets/ui/close_button2.dart';
import 'widgets/ui/responsive_view.dart';

export 'package:samsara/colors.dart';

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

final class TextStyles {
  static const displayLarge =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 36.0);
  static const displayMedium =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 34.0);
  static const displaySmall =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 32.0);
  static const headlineLarge =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 30.0);
  static const headlineMedium =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 28.0);
  static const headlineSmall =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 26.0);
  static const titleLarge =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 24.0);
  static const titleMedium =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 22.0);
  static const titleSmall =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 20.0);
  static const bodyLarge =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 18.0);
  static const bodyMedium =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 16.0);
  static const bodySmall =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 14.0);
  static const labelLarge =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 12.0);
  static const labelMedium =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 10.0);
  static const labelSmall =
      TextStyle(fontFamily: GameUI.fontFamily, fontSize: 8.0);
}

final class FluentButtonStyles {
  static final selected = fluent.ButtonStyle(
    backgroundColor: WidgetStateProperty<Color>.fromMap(
      <WidgetStatesConstraint, Color>{
        WidgetState.pressed | WidgetState.focused | WidgetState.selected:
            GameUI.focusColor,
        WidgetState.hovered: GameUI.hoverColor,
        WidgetState.disabled: Colors.transparent,
        WidgetState.any: GameUI.selectedColor,
      },
    ),
    foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
  );
}

final class Cursors {
  static const normal = 'normal';
  static const click = 'click';
  static const drag = 'drag';
  static const press = 'press';
}

class _GameCursor extends WidgetStateMouseCursor {
  const _GameCursor();

  /// Returns a [MouseCursor] that's to be used when a component is in the
  /// specified state.
  @override
  MouseCursor resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.hovered)) {
      return FlutterCustomMemoryImageCursor(key: Cursors.click);
    } else if (states.contains(WidgetState.pressed)) {
      return FlutterCustomMemoryImageCursor(key: Cursors.press);
    } else if (states.contains(WidgetState.dragged)) {
      return FlutterCustomMemoryImageCursor(key: Cursors.drag);
    } else {
      return FlutterCustomMemoryImageCursor(key: Cursors.normal);
    }
  }

  @override
  String get debugDescription => throw UnimplementedError();
}

final class GameUI {
  static Vector2 size = Vector2.zero();

  static Vector2 get center => size / 2;

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static const cursor = _GameCursor();

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

  // static const foregroundColor = GameColors.darkSlateGrey;
  // static const foregroundColorPressed = Colors.black;
  // static final foregroundDiabled = GameColors.lightSlateGrey;
  static const foregroundColor = Colors.white;
  static final foregroundDiabled = Colors.grey;

  static final barrierColor = Colors.black54;

  static const backgroundColor = Color(0xcc1b1613);
  static const backgroundColorOpaque = Color(0xff1b1613);
  static const backgroundColor2 = Color(0xcc270505);
  static const backgroundColor2Opaque = Color(0xff270505);

  static final Paint background2Paint = Paint()
    ..style = PaintingStyle.fill
    ..color = backgroundColor2;

  static const focusColor = Colors.deepPurple;
  static const hoverColor = Colors.lightBlue;
  static const selectedColor = Color(0xcc03a9f4);
  static const outlineColor = Colors.white54;
  static const highlightColor = Colors.yellow;

  static const borderColor = Color(0xaa607d8B);
  static const borderColor2 = Color(0xaacc5500);
  static const borderRadius = BorderRadius.all(Radius.circular(5.0));
  static const roundedRectangleBorder = RoundedRectangleBorder(
    side: BorderSide(
      color: borderColor,
      width: 2,
    ),
    borderRadius: GameUI.borderRadius,
  );
  static const boxBorder = Border.fromBorderSide(
    BorderSide(
      color: borderColor,
      width: 2,
    ),
  );

  static const boxDecoration = BoxDecoration(
    borderRadius: GameUI.borderRadius,
    border: boxBorder,
  );

  static const profileWindowPosition =
      Offset(largeIndent, heroInfoHeight + smallIndent);
  static final profileWindowSize = Vector2(640.0, 480.0);

  static late Offset detailsWindowPosition;

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

  static final darkMaterialTheme = ThemeData(
    splashFactory: NoSplash.splashFactory,
    brightness: Brightness.dark,
    textTheme: textTheme,
    fontFamily: GameUI.fontFamily,
    scaffoldBackgroundColor: Colors.transparent,
    iconTheme: iconTheme,
    dividerColor: foregroundColor,
    colorScheme: ColorScheme.dark(
      surface: backgroundColor,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      toolbarHeight: 36,
      iconTheme: iconTheme,
      actionsIconTheme: iconTheme,
      titleTextStyle: TextStyles.titleSmall,
    ),
    cardTheme: CardThemeData(
      elevation: 0.5,
      shape: roundedRectangleBorder,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        shape: roundedRectangleBorder,
        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyles.bodyMedium,
        foregroundColor: foregroundColor,
        shape: roundedRectangleBorder,
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
      textStyle: TextStyles.bodyMedium,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: backgroundColor,
      shape: roundedRectangleBorder,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: GameUI.fontFamily,
          fontSize: 15.0,
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: borderColor,
      activeTickMarkColor: borderColor,
      thumbColor: borderColor,
      valueIndicatorTextStyle: TextStyles.bodyMedium,
      showValueIndicator: ShowValueIndicator.never,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: TextStyles.bodyMedium,
      unselectedLabelStyle: TextStyles.bodyMedium,
    ),
  );

  static final fluentTheme = fluent.FluentThemeData(
    acrylicBackgroundColor: backgroundColor,
    accentColor: fluent.Colors.teal,
    brightness: Brightness.dark,
    fontFamily: GameUI.fontFamily,
    tooltipTheme: fluent.TooltipThemeData(
      textStyle: TextStyles.labelSmall,
    ),
    buttonTheme: fluent.ButtonThemeData(
      defaultButtonStyle: fluent.ButtonStyle(
        shape: WidgetStatePropertyAll<ShapeBorder>(
          roundedRectangleBorder,
        ),
      ),
      filledButtonStyle: fluent.ButtonStyle(
        backgroundColor: WidgetStateProperty<Color>.fromMap(
          <WidgetStatesConstraint, Color>{
            WidgetState.pressed | WidgetState.focused | WidgetState.selected:
                focusColor,
            WidgetState.hovered: hoverColor,
            WidgetState.disabled: Colors.blueGrey.withAlpha(80),
            WidgetState.any: backgroundColor,
          },
        ),
        foregroundColor: WidgetStateProperty<Color>.fromMap(
          <WidgetStatesConstraint, Color>{
            WidgetState.disabled: Colors.grey.withAlpha(80),
            WidgetState.any: foregroundColor,
          },
        ),
        shape: WidgetStatePropertyAll<ShapeBorder>(
          roundedRectangleBorder,
        ),
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        ),
        textStyle: WidgetStateProperty<TextStyle>.fromMap(
          <WidgetStatesConstraint, TextStyle>{
            WidgetState.disabled: TextStyles.bodyMedium
                .copyWith(color: Colors.grey.withAlpha(80)),
            WidgetState.any:
                TextStyles.bodyMedium.copyWith(color: foregroundColor),
          },
        ),
      ),
    ),
  );

  static final spriteButtonTextConfig = ScreenTextConfig(
    anchor: Anchor.center,
    textStyle: TextStyles.bodyMedium,
    outlined: true,
  );

  static final hovertipContentConfig = ScreenTextConfig(
    anchor: Anchor.topLeft,
    padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
    overflow: ScreenTextOverflow.wordwrap,
    textStyle: TextStyles.bodyMedium,
  );

  static const fadingTextStyle = TextStyle(
    color: foregroundColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static final siteTitleConfig = ScreenTextConfig(
    outlined: true,
    padding: EdgeInsets.only(top: 10),
    anchor: Anchor.topCenter,
    textStyle: TextStyles.titleSmall,
  );

  // location site scene ui
  static late Vector2 siteCardSize;
  static late Vector2 siteCardFocusedSize;
  static late Vector2 siteListPosition;
  static late Vector2 siteExitCardPositon;
  static const npcListArrowHeight = 25.0;

  // the relative paddings of the illustration rect
  static const cardIllustrationRelativePaddings =
      Rect.fromLTRB(0.06, 0.04, 0.06, 0.42);

  static final battleCardPreferredSize = Vector2(250, 250 * 1.382);
  static const battleCardTitlePaddings = EdgeInsets.fromLTRB(0, 0.585, 0, 0);

  static final Vector2 promptBannerSize = Vector2(640.0, 160.0);

  // ratio = height / width
  static const cardSizeRatio = 1.382;

  // deckbuilding ui
  static late Vector2 libraryCardSize;
  static late Vector2 deckbuildingCardSize;

  static final Vector2 deckbuildingZonePileOffset = Vector2(0, 30);
  static late Vector2 deckbuildingZoneButtonPosition;

  static late Vector2 decksZoneBackgroundSize;
  static late Vector2 decksZoneBackgroundPosition;
  static late Vector2 decksZoneCloseButtonPosition;

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
  static late List<Vector2> cardpackCardPositions;

  static late Vector2 craftZoneCloseButtonPosition;
  static late Vector2 cardLibraryExpLabelPosition;

  /// 原本是卡牌精炼区域，现在仅是贴图装饰
  static late Vector2 cardCraftZoneSize;
  static late Vector2 cardCraftZonePosition;
  // static late Vector2 cardCraftZonePosition2;

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
  static final buttonSizeSmall = Vector2(110, 40);
  static final buttonSizeMedium = Vector2(160, 60);
  static final buttonSizeLarge = Vector2(240, 80);
  static final buttonSizeSquare = Vector2(60, 60);
  static final buttonSizeLong = Vector2(180, 60);

  static final cultivationRankButtonSize = Vector2(120, 120);

  // 天赋树 ui
  static final skillButtonSizeSmall = Vector2(40, 40);
  static final skillButtonSizeMedium = Vector2(60, 60);
  static final skillButtonSizeLarge = Vector2(80, 80);

  // 消除游戏 ui
  static const matchingBoardGridWidth = 11;
  static const matchingBoardGridHeight = 7;

  static final matchingBoardOffset = Vector2(113.0, 135.0);
  static final matchingTileSrcSize = Vector2(81.0, 81.0);

  static final collectPanelPosition = Vector2(1000.0, 35.0);
  static final collectPanalSize = Vector2(420.0, 210.0);
  static final collectPanalAvatarSize = Vector2(120.0, 120.0);
  static final collectPanalAvatarPosition = Vector2(266, 46);
  // static final collectPanelIconSize = Vector2(60.0, 60.0);
  // static final collectPanelIconPositions = [
  //   Vector2(33.0, 45.0),
  //   Vector2(108.0, 45.0),
  //   Vector2(183.0, 45.0),
  //   Vector2(33.0, 105.0),
  //   Vector2(108.0, 105.0),
  //   Vector2(183.0, 105.0),
  // ];

  static final collectPanelIconPositions = [
    Vector2(70.0, 70.0),
    Vector2(155.0, 70.0),
  ];

  static void init() {
    SpriteButton.defaultTextConfig = spriteButtonTextConfig;

    Hovertip.backgroundPaint = Paint()
      ..color = backgroundColor2
      ..style = PaintingStyle.fill;

    Hovertip.defaultContentConfig = hovertipContentConfig;

    FadingText.defaultTextStyle = fadingTextStyle;
  }

  static void setSize(Vector2 newSize) {
    if (size == newSize) return;
    size = newSize;
    engine.info('画面尺寸修改为：${size.x}x${size.y}');

    // Hovertip.defaultContentConfig = Hovertip.defaultContentConfig.copyWith(
    //   textStyle: TextStyle(fontFamily: GameUI.fontFamily),
    // );

    detailsWindowPosition = Offset(
        newSize.x - profileWindowSize.x - largeIndent,
        profileWindowPosition.dy);

    libraryZonePosition = Vector2(
        (120 / defaultGameSize.width * newSize.x).roundToDouble(),
        (180 / defaultGameSize.height * newSize.y).roundToDouble());
    libraryZoneSize = Vector2(
        (960 / defaultGameSize.width * newSize.x).roundToDouble(),
        (450 / defaultGameSize.height * newSize.y).roundToDouble());

    libraryZoneBackgroundPosition = Vector2(0, libraryZonePosition.y);
    libraryZoneBackgroundSize = Vector2(
        (1190 / defaultGameSize.width * newSize.x).roundToDouble(),
        (libraryZoneSize.y).roundToDouble());

    orderByButtonPosition = libraryZonePosition + Vector2(35, -50);
    filterByButtonPosition =
        orderByButtonPosition + Vector2(buttonSizeLong.x + largeIndent, 0);

    decksZoneBackgroundSize = Vector2(
        newSize.x - libraryZoneBackgroundSize.x, libraryZoneBackgroundSize.y);
    decksZoneBackgroundPosition =
        Vector2(libraryZoneBackgroundSize.x, libraryZoneBackgroundPosition.y);

    final deckbuildingCardWidth =
        ((130 / defaultGameSize.width * newSize.x).roundToDouble());
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

    deckbuildingZoneButtonPosition = Vector2(
      decksZoneBackgroundPosition.x + smallIndent,
      decksZoneBackgroundPosition.y + decksZoneBackgroundSize.y,
    );

    decksZoneCloseButtonPosition = Vector2(
      deckbuildingZoneButtonPosition.x,
      deckbuildingZoneButtonPosition.y + buttonSizeMedium.y + indent,
    );

    final libraryCardWidth = libraryZoneSize.x / 5 - indent;
    final libraryCardHeight = libraryCardWidth * cardSizeRatio;
    libraryCardSize = Vector2(libraryCardWidth, libraryCardHeight);
    // libraryCardSize = deckbuildingCardSize;

    cardpackCardSize = libraryCardSize * 1.5;

    final position2 = Vector2(
      newSize.x / 2 - cardpackCardSize.x / 2,
      135.0,
    );
    final position1 = position2 - Vector2(cardpackCardSize.x + hugeIndent, 0);
    final position3 = position2 + Vector2(cardpackCardSize.x + hugeIndent, 0);

    cardpackCardPositions = [position1, position2, position3];

    craftZoneCloseButtonPosition = Vector2(
        newSize.x / 2, newSize.y - largeIndent - buttonSizeMedium.y / 2);

    cardLibraryExpLabelPosition = Vector2(newSize.x / 2, newSize.y - 50);

    cardCraftZoneSize = Vector2(
        (270 / defaultGameSize.width * newSize.x).roundToDouble(),
        (270 / defaultGameSize.height * newSize.y).roundToDouble());

    cardCraftZonePosition = Vector2(decksZoneBackgroundPosition.x, -150.0);

    // cardCraftZonePosition2 = decksZoneBackgroundPosition - Vector2(0, 100);

    skillBookPosition = Vector2(-60, GameUI.size.y - 160);
    // expBottlePosition = Vector2(size.x / 2, size.y - expBottleSize.y * 0.33);
    expBottlePosition = Vector2(
        skillBookPosition.x + skillBookSize.x + largeIndent,
        GameUI.size.y - expBottleSize.y * 0.33);

    battleCardSize = deckbuildingCardSize;
    battleDeckZoneSize =
        Vector2(newSize.x / 2 - largeIndent, battleCardSize.y + indent);

    battleCardFocusedSize =
        Vector2(battleCardSize.x + largeIndent, battleCardSize.y + largeIndent);

    p1BattleDeckZonePosition =
        Vector2(indent / 2, newSize.y - battleDeckZoneSize.y - indent / 2);
    p2BattleDeckZonePosition = Vector2(
        newSize.x - battleDeckZoneSize.x - indent / 2,
        p1BattleDeckZonePosition.y);

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
      newSize.x / 2 - 208,
      p1BattleDeckZonePosition.y - heroSpriteSize.y,
    );

    p2CharacterAnimationPosition = Vector2(
      newSize.x / 2 + 208,
      p2BattleDeckZonePosition.y - heroSpriteSize.y,
    );

    versusBannerSize = Vector2(520.0, 180.0);
    versusIconSize = Vector2(160.0, 180.0);
    battleCharacterAvatarSize = Vector2(100.0, 100.0);

    final siteCardWidth = (newSize.x - 300) / 8 - indent;
    final siteCardHeight = (siteCardWidth * 1.714).roundToDouble();

    siteCardSize = Vector2(siteCardWidth, siteCardHeight);

    siteCardFocusedSize = siteCardSize * 1.2;

    siteListPosition = Vector2(indent, newSize.y - indent - siteCardSize.y);

    siteExitCardPositon =
        Vector2(newSize.x - indent - siteCardSize.x, siteListPosition.y + 10);

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

  static void showConsole(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResponsiveView(
          margin: const EdgeInsets.all(50.0),
          child: Console(
            engine: engine,
            cursor: GameUI.cursor,
            margin:
                const EdgeInsets.symmetric(horizontal: 100.0, vertical: 50.0),
            backgroundColor: GameUI.backgroundColor,
            closeButton: CloseButton2(),
          ),
        );
      },
    );
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
