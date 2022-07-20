import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../event/events.dart';
import '../../../global.dart';
import '../../shared/label.dart';

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.locationData,
    required this.questData,
  });

  final HTStruct locationData, questData;

  @override
  Widget build(BuildContext context) {
    final heroData = engine.invoke('getHero');

    return Container(
      width: 240,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: kBorderRadius,
        border: Border.all(color: kForegroundColor),
      ),
      child: ClipRRect(
        borderRadius: kBorderRadius,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
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
              ),
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: ElevatedButton(
                  onPressed: () {
                    engine.invoke(
                      'characterAcceptQuest',
                      positionalArgs: [
                        heroData,
                        locationData,
                        questData,
                      ],
                    );
                    engine.broadcast(const UIEvent.needRebuildUI());
                  },
                  child: Label(
                    padding: const EdgeInsets.all(0.0),
                    engine.locale['takeQuest'],
                    width: 30.0,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
