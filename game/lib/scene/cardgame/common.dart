import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

final kGamepadSize = Vector2(1440.0, 900.0);
final kGamepadRect = Rect.fromLTWH(0, 0, kGamepadSize.x, kGamepadSize.y);
final kBorderRadius = kGamepadSize.y / 100;

const kCardIndent = 20.0;

const kLibraryCardWidth = 1440.0 / 6 - kCardIndent * 2;
const kLibraryCardHeight = kLibraryCardWidth * 1.382;
final kLibraryCardSize = Vector2(kLibraryCardWidth, kLibraryCardHeight);

// the ratio of the illustration height relative to the card height
const kCardIllustrationHeightRatio = 0.592;

const kDeckZoneCardWidth = (1440.0 - 300) / 8 - kCardIndent;
const kDeckZoneCardHeight = kDeckZoneCardWidth * 1.382;
final kDeckZoneCardSize = Vector2(kDeckZoneCardWidth, kDeckZoneCardHeight);

final kDeckZoneWidth = kGamepadSize.x;
const kDeckZoneHeight = kDeckZoneCardHeight * 1.2;
final kDeckZoneSize = Vector2(kDeckZoneWidth, kDeckZoneHeight);
final kDeckZonePileOffset = Vector2(kDeckZoneCardWidth + kCardIndent, 0);

final kLibraryWidth = kDeckZoneWidth;
final kLibraryHeight = kGamepadSize.y - kDeckZoneHeight;
final kLibrarySize = Vector2(kLibraryWidth, kLibraryHeight);
final kLibraryPosition = Vector2(0, kDeckZoneHeight);

const kFocusedCardWidth = kBattleCardWidth * 2;
const kFocusedCardHeight = kBattleCardHeight * 2;
final kFocusedCardSize = Vector2(kFocusedCardWidth, kFocusedCardHeight);

const kBattleCardWidth = kLibraryCardWidth;
const kBattleCardHeight = kLibraryCardHeight;
// final kBattleCardWidth = kGamepadSize.y / 8;
// final kBattleCardHeight = kBattleCardWidth * 1.4;
final kBattleCardSize = Vector2(kBattleCardWidth, kBattleCardHeight);

final kBattleDeckZoneWidth = kGamepadSize.x / 2 - kCardIndent;
const kBattleDeckZoneHeight = kBattleCardHeight + kCardIndent;
final kBattleDeckZoneSize =
    Vector2(kBattleDeckZoneWidth, kBattleDeckZoneHeight);

const kP1BattleDeckZoneLeft = 10.0;
final kP1BattleDeckZoneTop = kGamepadSize.y - kBattleDeckZoneHeight - 10;
final kP1BattleDeckZonePosition =
    Vector2(kP1BattleDeckZoneLeft, kP1BattleDeckZoneTop);
final kP2BattleDeckZoneLeft = kGamepadSize.x - kBattleDeckZoneWidth - 10;
final kP2BattleDeckZoneTop = kP1BattleDeckZoneTop;
final kP2BattleDeckZonePosition =
    Vector2(kP2BattleDeckZoneLeft, kP2BattleDeckZoneTop);

const kHeroWidth = 48.0 * 2;
const kHeroHeight = 80.0 * 2;
final kHeroSize = Vector2(kHeroWidth, kHeroHeight);

const kDraggingCardPriority = 200;
