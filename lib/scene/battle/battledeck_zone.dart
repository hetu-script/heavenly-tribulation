import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/components.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';

import '../../ui.dart';
import '../../global.dart';

class BattleDeckZone extends PiledZone with HandlesGesture {
  HovertipDirection hovertipDirection;

  BattleDeckZone({
    required super.position,
    super.focusedOffset,
    super.reverseX,
    super.isVisible,
    required this.hovertipDirection,
  }) : super(
          size: GameUI.battleDeckZoneSize,
          piledCardSize: GameUI.piledCardSize,
          pileOffset: Vector2(-1, -1),
          pileStyle: PileStyle.stack,
        ) {
    enableGesture = true;
    onMouseEnter = () {
      Hovertip.show(
        scene: game,
        target: this,
        content: '${engine.locale('deck_zone_card_count')}: ${cards.length}',
        width: 160.0,
        direction: hovertipDirection,
      );
    };
    onMouseExit = () {
      Hovertip.hide(this);
    };
  }
}
