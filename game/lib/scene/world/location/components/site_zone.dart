import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';
// import 'package:samsara/paint.dart';

import '../../../../ui.dart';

class SitesCards extends PiledZone {
  SitesCards({
    super.cards,
  }) : super(
          position: GameUI.siteListPosition,
          pileStructure: PileStructure.queue,
          piledCardSize: GameUI.siteCardSize,
          pileOffset: Vector2(GameUI.siteCardSize.x / 3 * 2, 0),
        );
}
