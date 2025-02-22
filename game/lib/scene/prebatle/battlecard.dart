import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';

import '../../ui.dart';
import '../../engine.dart';
import '../../state/hoverinfo.dart';
import '../../logic/battlecard.dart';
import '../common.dart';

class BattleCard extends StatelessWidget {
  BattleCard({
    required this.cardData,
    this.characterData,
    this.isHero = false,
    this.cardInfoDirection = HoverInfoDirection.rightTop,
  }) : super(key: GlobalKey());

  final dynamic cardData;
  final dynamic characterData;
  final bool isHero;
  final HoverInfoDirection cardInfoDirection;

  @override
  Widget build(BuildContext context) {
    TextStyle? textStyle;

    if (isHero) {
      final isUsable = checkCardRequirement(characterData, cardData);
      if (isUsable) {
        textStyle = TextStyle(color: Colors.red);
      }
    }

    final isIdentified = cardData['isIdentified'] == true;
    final name = cardData['name'];
    final title =
        isIdentified ? name : '$name - ${engine.locale('unidentified2')}';

    if (!isIdentified) {
      textStyle = TextStyle(color: Colors.grey);
    }

    return SizedBox(
      height: 40,
      width: 195,
      child: Card(
        shadowColor: Colors.black26,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(
                color: Colors.white,
                width: 1.0,
              ),
            ),
            borderRadius: GameUI.borderRadius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {}, // 必须有这个，否则无法触发onHover
              onHover: (bool entered) {
                if (entered) {
                  final rect = getRenderRect(context);
                  previewCard(
                    context,
                    'prebattle_card_${cardData['id']}',
                    cardData,
                    rect,
                    direction: cardInfoDirection,
                    characterData: isHero ? characterData : null,
                  );
                } else {
                  unpreviewCard(context);
                }
              },
              borderRadius: GameUI.borderRadius,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 5),
                child: Label(
                  title,
                  height: 20,
                  textAlign: TextAlign.left,
                  textStyle: textStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
