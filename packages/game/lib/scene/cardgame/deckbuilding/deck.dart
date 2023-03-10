import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/paint.dart';

import '../common.dart';

class DeckZone extends PiledZone {
  DeckZone()
      : super(
          size: kDeckZoneSize,
          piledCardSize: kLibraryCardSize,
          pileOffset: kDeckZonePileOffset,
        );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
