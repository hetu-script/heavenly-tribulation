import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';

import '../../ui.dart';
import '../../global.dart';

class BattleDeckZone extends PiledZone with HandlesGesture {
  BattleDeckZone({
    required super.position,
    super.cards,
    super.focusedOffset,
    super.reverseX,
    super.cardBasePriority,
    super.isVisible,
  }) : super(
          size: GameUI.battleDeckZoneSize,
          piledCardSize: GameUI.battleCardSize,
          pileOffset: Vector2(-1, -1),
          pileStyle: PileStyle.stack,
        );

  /// 将牌库中的卡牌随机打乱
  void shuffle() {
    cards.shuffle(engine.random);
    for (var i = 0; i < cards.length; ++i) {
      cards[i].index = i;
    }
    sortCards(animated: false);
  }
}
