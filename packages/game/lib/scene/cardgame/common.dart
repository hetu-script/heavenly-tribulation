import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

final kGamepadSize = Vector2(1280.0, 720.0);
final kGamepadRect = Rect.fromLTWH(0, 0, kGamepadSize.x, kGamepadSize.y);
final kBorderRadius = kGamepadSize.y / 100;

final kLibraryCardWidth = kGamepadSize.x / 9;
final kLibraryCardHeight = kLibraryCardWidth * 1.4;
final kLibraryCardSize = Vector2(kLibraryCardWidth, kLibraryCardHeight);

final kDeckZoneWidth = kGamepadSize.x;
final kDeckZoneHeight = kLibraryCardHeight * 1.2;
final kDeckZoneSize = Vector2(kDeckZoneWidth, kDeckZoneHeight);
final kDeckZonePileOffset = Vector2(kLibraryCardWidth + 10, 0);

final kFocusedCardWidth = kBattleCardWidth * 2;
final kFocusedCardHeight = kBattleCardHeight * 2;
final kFocusedCardSize = Vector2(kFocusedCardWidth, kFocusedCardHeight);

final kBattleCardWidth = kGamepadSize.y / 8;
final kBattleCardHeight = kBattleCardWidth * 1.4;
final kBattleCardSize = Vector2(kBattleCardWidth, kBattleCardHeight);

final kBattleDeckZoneWidth = kGamepadSize.x / 2 - 20;
final kBattleDeckZoneHeight = kBattleCardHeight + 20;
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

const kCharacterWidth = 800.0;
const kCharacterHeight = 640.0;
