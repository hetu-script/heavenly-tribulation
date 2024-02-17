import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/cardgame.dart';

import 'common.dart';

class CardPreview extends GameComponent {
  final PlayingCard card;

  CardPreview(this.card) : super(size: kGamepadSize);

  @override
  void onLoad() {}
}
