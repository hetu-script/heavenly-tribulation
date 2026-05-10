import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';

import '../../ui.dart';

class DiscardZone extends PiledZone with HandlesGesture {
  DiscardZone({
    required super.position,
    super.cards,
    super.reverseX,
    super.isVisible,
  }) : super(
          size: GameUI.battleDeckZoneSize,
          piledCardSize: GameUI.battleDeckZoneSize * 0.6,
          pileOffset: Vector2(-0.6, -0.6),
          pileStyle: PileStyle.stack,
        );
}
