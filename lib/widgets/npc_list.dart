import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/engine.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/ink_button.dart';

import 'avatar.dart';
import '../state/current_npc_list.dart';
// import '../../state/game_dialog_state.dart';
import '../game/ui.dart';
import '../game/data.dart';

class NpcList extends StatefulWidget {
  const NpcList({super.key});

  @override
  State<NpcList> createState() => _NpcListState();
}

class _NpcListState extends State<NpcList> {
  int start = 0, length = 0, end = 0;

  double availableSpaceY = 0;

  @override
  void initState() {
    super.initState();

    availableSpaceY = GameUI.size.y -
        GameUI.heroInfoHeight -
        GameUI.siteCardSize.y -
        GameUI.indent * 2 -
        GameUI.npcListArrowHeight * 2;

    length = availableSpaceY ~/ GameUI.avatarSize;
  }

  void setStartIndex(int index) {}

  @override
  Widget build(BuildContext context) {
    if (GameData.heroData == null) {
      return Container();
    }

    final characters =
        (context.watch<NpcListState>().npcs).map((characterData) {
      final haveMet = engine.hetu.invoke('haveMet',
          positionalArgs: [GameData.heroData, characterData]);
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Avatar(
            cursor: SystemMouseCursors.click,
            color: GameUI.backgroundColor,
            displayName: (haveMet != null) ? characterData['name'] : '???',
            size: const Size(80, 80),
            characterData: characterData,
            borderWidth: 1.0,
            borderRadius: 5.0,
            onPressed: (charId) {
              // if (characterData['entityType'] == 'character') {
              engine.hetu.invoke('onInteractCharacter',
                  positionalArgs: [characterData]);
              // } else {
              //   engine.hetu.invoke('onInteractLocationObject',
              //       positionalArgs: [characterData]);
              // }
            }),
      );
    }).toList();

    end = start + length;

    if (end >= characters.length) {
      end = characters.length;
    }

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          SizedBox(
            height: 25.0,
            child: start > 0
                ? InkButton(
                    size: const Size(125.0, 25.0),
                    image: const AssetImage('assets/images/ui/arrow_up.png'),
                    onPressed: () {
                      setState(() {
                        --start;
                        --end;
                      });
                    },
                  )
                : null,
          ),
          ...characters.sublist(start, end),
          SizedBox(
            height: 25.0,
            child: end < characters.length
                ? InkButton(
                    size: const Size(125.0, 25.0),
                    image: const AssetImage('assets/images/ui/arrow_down.png'),
                    onPressed: () {
                      setState(() {
                        ++start;
                        ++end;
                      });
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
