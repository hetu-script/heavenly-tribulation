import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';
// import 'package:samsara/paint.dart';
import 'package:samsara/components/hovertip.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/paint/paint.dart';

import '../../../ui.dart';
// import '../../../global.dart';
// import 'character.dart';

class BattleDeckZone extends PiledZone with HandlesGesture {
  late GameCard current;

  BattleDeckZone({
    required super.position,
    super.cards,
    super.focusedOffset,
    super.pileStructure,
    required super.reverseX,
  }) : super(
          size: GameUI.battleDeckZoneSize,
          piledCardSize: GameUI.battleCardSize,
          pileMargin: Vector2(10, 10),
          pileOffset: Vector2(GameUI.battleCardSize.x / 3 * 2, 0),
          focusedSize: GameUI.battleCardFocusedSize,
        );

  @override
  void onLoad() {
    assert(cards.isNotEmpty && cards.length >= 3);

    current = cards.first;
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      card.prev = i == 0 ? cards.last : cards[i - 1];
      card.next = i == (cards.length - 1) ? cards.first : cards[i + 1];
      card.index = i;
      card.previewPriority = card.focusedPriority = 200;

      if (!card.isMounted) {
        gameRef.world.add(card);
      }

      card.onPreviewed = () {
        Hovertip.show(
          scene: game,
          target: card,
          direction: HovertipDirection.topLeft,
          content: (card as CustomGameCard).extraDescription,
          config: ScreenTextConfig(anchor: Anchor.topCenter),
        );
      };

      card.onUnpreviewed = () {
        if (!card.isFocused) {
          Hovertip.hide(card);
        }
      };
    }

    super.onLoad();
  }

  GameCard nextCard() {
    current = current.next!;
    if (current.index == 0) {
      for (final card in cards) {
        card.isEnabled = true;
      }
    }
    return current;
  }

  void reset() {
    current = cards.first;
    for (final card in cards) {
      card.isEnabled = true;
      if (card.isFocused) {
        card.setFocused(false);
      }
      card.enablePreview = true;
    }
  }

  // @override
  // void render(Canvas canvas) {
  //   canvas.drawRRect(rrect, PredefinedPaints.light);
  // }
}
