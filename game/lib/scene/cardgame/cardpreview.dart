import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/cardgame.dart';

import '../../ui.dart';

class CardPreview extends GameComponent {
  final PlayingCard card;

  CardPreview(this.card) : super(size: GameUI.size);

  @override
  void onLoad() {}
}
