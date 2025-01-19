import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';
// import 'package:samsara/paint.dart';
import 'package:samsara/components/hovertip.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/paint/paint.dart';

import '../../ui.dart';
import '../../data.dart';
// import '../../../global.dart';
// import 'character.dart';

class BattleDeckZone extends PiledZone with HandlesGesture {
  CustomGameCard? current;

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
          pileOffset: Vector2(GameUI.battleCardSize.x / 5 * 3, 0),
          focusedSize: GameUI.battleCardFocusedSize,
        );

  @override
  void onLoad() {
    super.onLoad();

    // assert(cards.isNotEmpty && cards.length >= 3);

    if (cards.isNotEmpty) {
      current = cards.first as CustomGameCard;
      for (var i = 0; i < cards.length; ++i) {
        final card = cards[i];
        card.next = i < (cards.length - 1) ? cards[i + 1] : null;
        card.index = i;
        card.previewPriority = card.focusedPriority = 200;

        if (!card.isMounted) {
          game.world.add(card);
        }

        card.onPreviewed = () {
          final (_, description) = GameData.getDescriptionFromCardData(
              (card as CustomGameCard).data);
          Hovertip.show(
            scene: game,
            target: card,
            direction: HovertipDirection.topLeft,
            content: description,
            config: ScreenTextConfig(anchor: Anchor.topCenter),
          );
        };

        card.onUnpreviewed = () {
          if (!card.isFocused) {
            Hovertip.hide(card);
          }
        };
      }
    }
  }

  void reset() {
    current = cards.firstOrNull as CustomGameCard?;
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
