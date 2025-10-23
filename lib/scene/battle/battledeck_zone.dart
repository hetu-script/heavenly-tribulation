import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/components/ui/hovertip.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';

import '../../ui.dart';
import '../../data/game.dart';
import 'battle.dart';

class BattleDeckZone extends PiledZone with HandlesGesture {
  CustomGameCard? current;

  bool isFirstCard = true;

  // turn 指一张牌，round 指整个卡组一轮
  int round = 0;

  BattleDeckZone({
    required super.position,
    super.cards,
    super.focusedOffset,
    super.pileStyle,
    required super.reverseX,
    super.cardBasePriority,
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
          final isDetailed = (game as BattleScene).isDetailedHovertip;
          final (_, description) = GameData.getBattleCardDescription(
            (card as CustomGameCard).data,
            isDetailed: isDetailed,
            showDetailedHint: false,
          );
          Hovertip.show(
            scene: game,
            target: card,
            direction: HovertipDirection.topCenter,
            content: description,
            config: ScreenTextConfig(
              anchor: Anchor.topCenter,
              textAlign: TextAlign.center,
            ),
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
