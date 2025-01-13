import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame.dart';

import '../../state/hover_info.dart';

const kBarrierPriority = 100000;

const kDraggingCardPriority = 5000;

const kDeckCoverPriority = 2005;

const kTopBarPriority = 3000;

const kDeckPilesZonePriority = 2000;

const kCardCraftingZonePriority = 3010;

const kBottomBarPriority = 4000;

void previewCard(Scene game, CustomGameCard card,
    {HoverInfoDirection? direction}) {
  final position = card.absolutePosition;
  final size = card.absoluteScaledSize;
  game.context.read<HoverInfoContentState>().set(
        card.data,
        Rect.fromLTWH(position.x, position.y, size.x, size.y),
        direction: direction ?? HoverInfoDirection.rightTop,
      );
}

void unpreviewCard(Scene game, CustomGameCard card) {
  game.context.read<HoverInfoContentState>().hide();
}
