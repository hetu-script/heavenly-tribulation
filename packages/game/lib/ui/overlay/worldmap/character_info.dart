import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/ui/view/character/build/build.dart';
import 'package:hetu_script/values.dart';

import '../../shared/avatar.dart';
import '../../view/character/character.dart';
import '../../../global.dart';
import '../../shared/bordered_icon_button.dart';
import '../../view/character/build/build.dart';

class HeroInfoPanel extends StatelessWidget {
  const HeroInfoPanel({Key? key, required this.heroData}) : super(key: key);

  final HTStruct heroData;

  @override
  Widget build(BuildContext context) {
    final heroInfoRow = <Widget>[];
    heroInfoRow.addAll([
      Avatar(
        margin: const EdgeInsets.only(right: 8.0),
        avatarAssetKey: 'assets/images/${heroData['avatar']}',
        onPressed: () {
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) {
              return CharacterView(characterId: heroData['id']);
            },
          );
        },
      ),
      Expanded(
        child: Column(
          children: <Widget>[
            const Spacer(),
            Row(
              children: <Widget>[
                BorderedIconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      builder: (context) {
                        return BuildView(characterId: heroData['id']);
                      },
                    );
                  },
                  icon: const Image(
                    image: AssetImage('assets/images/icon/build.png'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ]);

    return Container(
      width: 180,
      height: 100,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: GlobalConfig.theme.backgroundColor,
        borderRadius:
            const BorderRadius.only(bottomRight: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: heroInfoRow,
      ),
    );
  }
}
