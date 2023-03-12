import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../global.dart';

class QuestInfoPanel extends StatelessWidget {
  const QuestInfoPanel({
    super.key,
    this.characterData,
  });

  final HTStruct? characterData;

  @override
  Widget build(BuildContext context) {
    final heroData = characterData ?? engine.invoke('getHero');
    final questData =
        engine.invoke('getCharacterActiveQuest', positionalArgs: [heroData]);

    return Container(
      width: 300,
      height: 130,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        // borderRadius:
        //     const BorderRadius.only(bottomRight: Radius.circular(5.0)),
        border: Border.all(color: kForegroundColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            engine.locale[questData['category']],
            style: const TextStyle(fontSize: 16.0),
          ),
          const Divider(),
          Text(
            questData['description'],
            style: const TextStyle(fontSize: 12.0),
          ),
        ],
      ),
    );
  }
}
