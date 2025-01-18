import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';

import '../../ui.dart';
// import '../../engine.dart';
import '../../data.dart';
import '../../state/hover_info.dart';
import '../../logic/battlecard.dart';

class BattleCard extends StatelessWidget {
  BattleCard({
    required this.cardData,
    this.characterData,
    this.isHero = false,
  }) : super(key: GlobalKey());

  final dynamic cardData;
  final dynamic characterData;
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    bool isUsable = true;

    if (isHero) {
      isUsable = checkCardRequirement(characterData, cardData);
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
            // image: DecorationImage(
            //   image: AssetImage(
            //       'assets/images/cultivation/battlecard/illustration/${cardData['image']}'),
            //   fit: BoxFit.fill,
            // ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {}, // 必须有这个，否则无法触发onHover
              onHover: (bool entered) {
                if (entered) {
                  final rect = getRenderRect(context);
                  final (_, description) = GameData.getDescriptionFromCardData(
                      cardData,
                      characterData: isHero ? characterData : null);
                  context.read<HoverInfoContentState>().set(description, rect);
                } else {
                  context.read<HoverInfoContentState>().hide();
                }
              },
              borderRadius: GameUI.borderRadius,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 5),
                child: Label(
                  cardData['name'],
                  height: 20,
                  textAlign: TextAlign.left,
                  textStyle: isUsable ? null : TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
