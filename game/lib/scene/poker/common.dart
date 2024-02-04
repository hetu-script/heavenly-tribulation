import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

final kGamepadSize = Vector2(1280.0, 720.0);
final kGamepadRect = Rect.fromLTWH(0, 0, kGamepadSize.x, kGamepadSize.y);
final kBorderRadius = kGamepadSize.y / 100;

final kLibraryCardWidth = kGamepadSize.x / 9;
final kLibraryCardHeight = kLibraryCardWidth * 1.4;
final kLibraryCardSize = Vector2(kLibraryCardWidth, kLibraryCardHeight);
