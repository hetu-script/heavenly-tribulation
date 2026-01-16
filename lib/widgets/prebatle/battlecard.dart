import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:samsara/hover_info.dart';

import '../../ui.dart';
import '../../global.dart';
import '../../logic/logic.dart';
import '../../widgets/common.dart';

class BattleCard extends StatelessWidget {
  BattleCard({
    required this.data,
    this.character,
    this.isHero = false,
    this.cardInfoDirection = HoverContentDirection.rightTop,
  }) : super(key: GlobalKey());

  final dynamic data;
  final dynamic character;
  final bool isHero;
  final HoverContentDirection cardInfoDirection;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(color: Colors.white);

    final isIdentified = data['isIdentified'] == true;
    final name = data['name'];
    final title =
        isIdentified ? name : '$name - ${engine.locale('unidentified2')}';

    if (!isIdentified) {
      textStyle = TextStyle(color: Colors.grey);
    } else {
      if (isHero) {
        final warning = GameLogic.checkRequirements(data);
        if (warning != null) {
          textStyle = TextStyle(color: Colors.red);
        }
      }
    }

    return SizedBox(
      height: 40,
      width: 195,
      child: Card(
        shadowColor: Colors.black26,
        child: Ink(
          decoration: GameUI.boxDecoration,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {}, // 必须有这个，否则无法触发onHover
              onHover: (bool entered) {
                if (entered) {
                  final rect = getRenderRect(context);
                  previewCard(
                    'prebattle_card_${data['id']}',
                    data,
                    rect,
                    isLibrary: isHero,
                    direction: cardInfoDirection,
                    character: isHero ? character : null,
                  );
                } else {
                  unpreviewCard();
                }
              },
              borderRadius: GameUI.borderRadius,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 5),
                child: Label(
                  title,
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
