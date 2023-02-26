import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

final kGamepadSize = Vector2(1280.0, 720.0);
final kGamepadRect = Rect.fromLTWH(0, 0, kGamepadSize.x, kGamepadSize.y);
final kBorderRadius = kGamepadSize.y / 100;

final kCardWidth = kGamepadSize.y / 8;
final kCardHeight = kCardWidth * 1.4;
final kCardSize = Vector2(kCardWidth, kCardHeight);
final kCardRadius = kCardWidth / 32;

final kFocusedCardWidth = kCardWidth * 2;
final kFocusedCardHeight = kCardHeight * 2;
final kFocusedCardSize = Vector2(kFocusedCardWidth, kFocusedCardHeight);

final kDeckZoneWidth = kGamepadSize.x / 2 - 20;
final kDeckZoneHeight = kCardHeight + 20;

const kPlayer1DeckZoneLeft = 10.0;
final kPlayer1DeckZoneTop = kGamepadSize.y - kDeckZoneHeight - 10;
final kPlayer2DeckZoneLeft = kGamepadSize.x - kDeckZoneWidth - 10;
final kPlayer2DeckZoneTop = kPlayer1DeckZoneTop;
