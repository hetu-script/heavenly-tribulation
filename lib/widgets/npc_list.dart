import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/global.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/ink_button.dart';
import 'package:samsara/game_dialog/avatar.dart';

import '../ui.dart';
import '../data/game.dart';
import '../logic/logic.dart';
import '../state/game_state.dart';

class NpcList extends StatefulWidget {
  const NpcList({
    super.key,
    this.onInteract,
    this.showNamesWithoutMeeting = false,
  });

  final FutureOr<void> Function(dynamic character)? onInteract;
  final bool showNamesWithoutMeeting;

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

  @override
  Widget build(BuildContext context) {
    if (GameData.hero == null) {
      return SizedBox.shrink();
    }

    final characters = (context.watch<GameState>().npcs).map((character) {
      final haveMet = engine.hetu
          .invoke('haveMet', positionalArgs: [GameData.hero, character]);
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Avatar(
          imageId: character['icon'],
          color: GameUI.foregroundColor,
          name: (widget.showNamesWithoutMeeting || haveMet != null)
              ? character['name']
              : '???',
          size: const Size(100, 100),
          data: character,
          onPressed: (character) {
            final onInteract = widget.onInteract;
            if (onInteract != null) {
              onInteract(character);
            } else {
              GameLogic.onInteractCharacter(character);
            }
          },
        ),
      );
    }).toList();

    final maxStart =
        characters.length > length ? characters.length - length : 0;
    if (start > maxStart) start = maxStart;
    end = start + length;
    if (end > characters.length) end = characters.length;

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
