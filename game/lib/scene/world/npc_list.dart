import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/engine.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/ink_button.dart';

import '../../view/avatar.dart';
import '../../state/current_npc_list.dart';
// import '../../state/game_dialog_state.dart';
import '../../ui.dart';

class NpcList extends StatefulWidget {
  const NpcList({
    super.key,
    // this.npcs,
  });

  // final Iterable<dynamic>? npcs;

  @override
  State<NpcList> createState() => _NpcListState();
}

class _NpcListState extends State<NpcList> {
  int start = 0, length = 0, end = 0;

  double availableSpaceY = 0;

  @override
  void initState() {
    // TODO: implement initState
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
    final hero = engine.hetu.fetch('hero');
    final characters = (
            // widget.npcs ??
            context.watch<CurrentNpcList>().characters)
        .map((char) {
      final haveMet =
          engine.hetu.invoke('haveMet', positionalArgs: [hero, char]);
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Avatar(
            color: GameUI.backgroundColor,
            displayName: haveMet ? char['name'] : '???',
            size: const Size(120, 120),
            characterData: char,
            onPressed: (charId) {
              engine.hetu
                  .invoke('onInteractCharacter', positionalArgs: [charId]);
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
            width: 125.0,
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
            width: 125.0,
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
