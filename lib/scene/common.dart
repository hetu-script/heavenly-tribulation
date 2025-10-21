import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hover_content.dart';

const kMaxHeroAge = 17;

const kWorldMapAnimationPriority = 15000;

const kSiteCardPriority = 500;

const kMouseCursorEffectPriority = 99999999;

enum MouseCursorState {
  normal,
  click,
  drag,
}

final class Scenes {
  static const mainmenu = 'mainmenu';
  static const library = 'library';
  static const cultivation = 'cultivation';
  static const worldmap = 'worldmap';
  static const location = 'location';
  static const battle = 'battle';

  static const matchingGame = 'matching_game';

  /// 下面的 id 仅用于事件注册
  static const editor = 'editor';
  static const prebattle = 'prebattle';
}

const kLocationKindHome = 'home';
const kLocationKindResidence = 'residence';

void previewCard(
  BuildContext context,
  String id,
  dynamic cardData,
  Rect rect, {
  bool isLibrary = true,
  HoverContentDirection? direction,
  dynamic character,
}) {
  context.read<HoverContentState>().show(
        cardData,
        rect,
        type: isLibrary ? ItemType.player : ItemType.none,
        direction: direction ?? HoverContentDirection.rightTop,
        data2: character,
      );
}

void unpreviewCard(BuildContext context) {
  context.read<HoverContentState>().hide();
}
